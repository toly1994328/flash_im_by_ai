//! WebSocket 连接处理
//!
//! 使用 Protobuf 二进制协议进行通信。
//! 连接生命周期：握手 → 认证（10s 超时） → 消息循环 → 断开。

use axum::{
    extract::ws::{Message, WebSocket, WebSocketUpgrade},
    response::IntoResponse,
};
use futures::{SinkExt, StreamExt};
use prost::Message as ProstMessage;

use flash_core::jwt::verify_token;

use crate::dispatcher::handle_frame;
use crate::proto::{AuthRequest, AuthResult, WsFrame, WsFrameType};

/// GET /ws/im — WebSocket 升级端点
pub async fn ws_handler(ws: WebSocketUpgrade) -> impl IntoResponse {
    ws.on_upgrade(handle_socket)
}

/// 处理单个 WebSocket 连接
async fn handle_socket(socket: WebSocket) {
    let (mut sender, mut receiver) = socket.split();

    // 等待认证（10 秒超时）
    let user_id = match tokio::time::timeout(
        std::time::Duration::from_secs(10),
        wait_for_auth(&mut receiver),
    )
    .await
    {
        Ok(Some(uid)) => uid,
        Ok(None) => {
            let _ = send_auth_result(&mut sender, false, "Token invalid").await;
            return;
        }
        Err(_) => {
            let _ = send_auth_result(&mut sender, false, "Auth timeout").await;
            return;
        }
    };

    // 认证成功
    let _ = send_auth_result(&mut sender, true, "OK").await;
    println!("✅ [im-ws] user {} connected", user_id);

    // 消息循环
    while let Some(Ok(msg)) = receiver.next().await {
        let data = match msg {
            Message::Binary(data) => data,
            Message::Close(_) => break,
            _ => continue,
        };

        let frame = match WsFrame::decode(data.as_ref()) {
            Ok(f) => f,
            Err(_) => continue,
        };

        if let Some(reply) = handle_frame(frame) {
            if sender.send(Message::Binary(reply.into())).await.is_err() {
                break;
            }
        }
    }

    println!("❌ [im-ws] user {} disconnected", user_id);
}

/// 等待客户端发送 AUTH 帧，解析 token，返回 user_id
async fn wait_for_auth(
    receiver: &mut futures::stream::SplitStream<WebSocket>,
) -> Option<i64> {
    while let Some(Ok(msg)) = receiver.next().await {
        if let Message::Binary(data) = msg {
            let frame = WsFrame::decode(data.as_ref()).ok()?;
            if frame.r#type != WsFrameType::Auth as i32 {
                return None;
            }
            let auth_req = AuthRequest::decode(frame.payload.as_slice()).ok()?;
            return verify_token(&auth_req.token).ok();
        }
    }
    None
}

/// 发送 AUTH_RESULT 帧
async fn send_auth_result(
    sender: &mut futures::stream::SplitSink<WebSocket, Message>,
    success: bool,
    message: &str,
) -> Result<(), axum::Error> {
    let result = AuthResult {
        success,
        message: message.to_string(),
    };
    let frame = WsFrame {
        r#type: WsFrameType::AuthResult as i32,
        payload: result.encode_to_vec(),
    };
    sender
        .send(Message::Binary(frame.encode_to_vec().into()))
        .await
}
