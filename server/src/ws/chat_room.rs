use axum::extract::ws::{Message, WebSocket};
use futures::{SinkExt, StreamExt};
use std::sync::Arc;

use flash_core::state::AppState;
use super::auth::wait_for_auth;

/// [Playground] 聊天室端点：认证 → 多人广播
/// 认证成功后进入广播模式，所有在线用户共享同一个聊天室
pub async fn handle_chat_room(mut socket: WebSocket, state: Arc<AppState>) {
    println!("🔗 [chat_room] 连接已建立，等待认证...");

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
            return;
        }
        Err(_) => {
            let _ = socket.send(Message::Text(r#"{"type":"auth_timeout","message":"认证超时"}"#.into())).await;
            let _ = socket.send(Message::Close(None)).await;
            return;
        }
    };

    let welcome = format!(
        r#"{{"type":"auth_ok","user_id":{},"nickname":"{}","avatar":"{}"}}"#,
        user.user_id, user.nickname, user.avatar
    );
    let _ = socket.send(Message::Text(welcome.into())).await;
    println!("✅ [chat_room] {} (ID:{}) 进入聊天室", user.nickname, user.user_id);

    let join_msg = format!(
        r#"{{"type":"join","user_id":{},"nickname":"{}","avatar":"{}"}}"#,
        user.user_id, user.nickname, user.avatar
    );
    let _ = state.chat_tx.send(join_msg);

    let mut rx = state.chat_tx.subscribe();
    let tx = state.chat_tx.clone();
    let uid = user.user_id;
    let nick = user.nickname.clone();
    let avatar = user.avatar.clone();

    let (mut ws_sink, mut ws_stream) = socket.split();

    let send_task = tokio::spawn(async move {
        while let Ok(msg) = rx.recv().await {
            if ws_sink.send(Message::Text(msg.into())).await.is_err() {
                break;
            }
        }
    });

    while let Some(Ok(msg)) = ws_stream.next().await {
        match msg {
            Message::Text(text) => {
                let broadcast_msg = format!(
                    r#"{{"type":"message","user_id":{},"nickname":"{}","avatar":"{}","text":{}}}"#,
                    uid, nick, avatar, serde_json::to_string(&text.to_string()).unwrap_or_default()
                );
                let _ = tx.send(broadcast_msg);
            }
            Message::Close(_) => break,
            _ => {}
        }
    }

    let leave_msg = format!(
        r#"{{"type":"leave","user_id":{},"nickname":"{}","avatar":"{}"}}"#,
        uid, nick, avatar
    );
    let _ = tx.send(leave_msg);
    send_task.abort();
    println!("❌ [chat_room] {} 离开聊天室", nick);
}
