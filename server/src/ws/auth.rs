use axum::extract::ws::{Message, WebSocket};
use futures::StreamExt;
use std::sync::Arc;

use flash_core::jwt::verify_token;
use flash_core::state::{AppState, User};

/// 等待客户端发送 Token 进行认证，从数据库查询用户信息
pub async fn wait_for_auth(socket: &mut WebSocket, state: &Arc<AppState>) -> Option<User> {
    while let Some(Ok(msg)) = socket.next().await {
        if let Message::Text(text) = msg {
            if let Ok(parsed) = serde_json::from_str::<serde_json::Value>(&text) {
                if let Some(token) = parsed.get("token").and_then(|t| t.as_str()) {
                    if let Ok(user_id) = verify_token(token) {
                        return find_user(state, user_id).await;
                    }
                }
            }
            return None;
        }
    }
    None
}

/// 从数据库查询用户信息
async fn find_user(state: &Arc<AppState>, user_id: i64) -> Option<User> {
    let row: Option<(i64, String, Option<String>)> = sqlx::query_as(
        "SELECT p.account_id, p.nickname, p.avatar
         FROM user_profiles p
         JOIN accounts a ON a.id = p.account_id
         WHERE p.account_id = $1 AND a.status = 0"
    )
    .bind(user_id)
    .fetch_optional(&state.db)
    .await
    .ok()?;

    let (account_id, nickname, avatar) = row?;

    let phone_row: Option<(String,)> = sqlx::query_as(
        "SELECT identifier FROM auth_credentials
         WHERE account_id = $1 AND auth_type = 'phone'"
    )
    .bind(account_id)
    .fetch_optional(&state.db)
    .await
    .ok()?;

    let phone = phone_row.map(|(p,)| p).unwrap_or_default();

    Some(User {
        user_id: account_id,
        phone,
        nickname,
        avatar: avatar.unwrap_or_default(),
        signature: String::new(),
    })
}

/// [Playground] 带认证的 WebSocket echo 测试端点
pub async fn handle_auth_socket(mut socket: WebSocket, state: Arc<AppState>) {
    println!("🔗 [ws/auth] 连接已建立，等待认证...");

    let auth_result = tokio::time::timeout(
        std::time::Duration::from_secs(10),
        wait_for_auth(&mut socket, &state),
    )
    .await;

    let user = match auth_result {
        Ok(Some(u)) => u,
        Ok(None) => {
            let _ = socket.send(Message::Text(r#"{"type":"auth_fail","message":"Token 无效"}"#.into())).await;
            let _ = socket.send(Message::Close(None)).await;
            println!("❌ [ws/auth] 认证失败");
            return;
        }
        Err(_) => {
            let _ = socket.send(Message::Text(r#"{"type":"auth_timeout","message":"认证超时"}"#.into())).await;
            let _ = socket.send(Message::Close(None)).await;
            println!("⏰ [ws/auth] 认证超时（10s）");
            return;
        }
    };

    let welcome = format!(
        r#"{{"type":"auth_ok","user_id":{},"nickname":"{}"}}"#,
        user.user_id, user.nickname
    );
    let _ = socket.send(Message::Text(welcome.into())).await;
    println!("✅ [ws/auth] 用户 {} (ID:{}) 认证成功", user.nickname, user.user_id);

    while let Some(Ok(msg)) = socket.next().await {
        match msg {
            Message::Text(text) => {
                println!("📨 [ws/auth] 用户{}说: {text}", user.user_id);
                let reply = format!(
                    r#"{{"type":"message","from":{},"text":"echo: {text}"}}"#,
                    user.user_id
                );
                if socket.send(Message::Text(reply.into())).await.is_err() {
                    break;
                }
            }
            Message::Close(_) => break,
            _ => {}
        }
    }

    println!("❌ [ws/auth] 用户 {} 断开连接", user.user_id);
}
