use axum::extract::ws::{Message, WebSocket};
use futures::StreamExt;
use std::sync::Arc;

use crate::auth::jwt::verify_token;
use crate::state::{AppState, User};

/// 等待客户端发送 Token 进行认证（公共函数，chat_room 等端点复用）
pub async fn wait_for_auth(socket: &mut WebSocket, state: &Arc<AppState>) -> Option<User> {
    while let Some(Ok(msg)) = socket.next().await {
        if let Message::Text(text) = msg {
            if let Ok(parsed) = serde_json::from_str::<serde_json::Value>(&text) {
                if let Some(token) = parsed.get("token").and_then(|t| t.as_str()) {
                    if let Ok(user_id) = verify_token(token) {
                        let users = state.users.lock().await;
                        return users.values().find(|u| u.user_id == user_id).cloned();
                    }
                }
            }
            return None;
        }
    }
    None
}

/// [Playground] 带认证的 WebSocket echo 测试端点
/// 认证成功后进入 echo 模式（你发什么回什么），用于验证 WebSocket + JWT 整合流程
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
