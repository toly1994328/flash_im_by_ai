//! WebSocket 连接处理

use std::sync::Arc;
use axum::{
    extract::{ws::{Message, WebSocket, WebSocketUpgrade}, State},
    response::IntoResponse,
};
use futures::{SinkExt, StreamExt};
use prost::Message as ProstMessage;
use tokio::sync::mpsc;

use flash_core::jwt::verify_token;

use crate::proto::{AuthRequest, AuthResult, WsFrame, WsFrameType};
use crate::state::WsState;
use crate::dispatcher::MessageDispatcher;

pub struct WsHandlerState {
    pub ws_state: Arc<WsState>,
    pub dispatcher: Arc<MessageDispatcher>,
}

pub async fn ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<Arc<WsHandlerState>>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_socket(socket, state))
}

async fn handle_socket(socket: WebSocket, state: Arc<WsHandlerState>) {
    let (mut ws_sender, mut ws_receiver) = socket.split();

    // 认证
    let user_id = match tokio::time::timeout(
        std::time::Duration::from_secs(10),
        wait_for_auth(&mut ws_receiver),
    ).await {
        Ok(Some(uid)) => uid,
        _ => {
            let _ = send_frame(&mut ws_sender, WsFrameType::AuthResult,
                &AuthResult { success: false, message: "Auth failed".into() }).await;
            return;
        }
    };

    let _ = send_frame(&mut ws_sender, WsFrameType::AuthResult,
        &AuthResult { success: true, message: "OK".into() }).await;
    println!("✅ [im-ws] user {} connected", user_id);

    // 创建推送通道，注册到在线用户表
    let (tx, mut rx) = mpsc::unbounded_channel::<Vec<u8>>();
    state.ws_state.add(user_id, tx).await;

    // spawn 发送任务：从 channel 读数据，写到 WebSocket
    let send_task = tokio::spawn(async move {
        while let Some(data) = rx.recv().await {
            if ws_sender.send(Message::Binary(data.into())).await.is_err() {
                break;
            }
        }
    });

    // 接收循环：从 WebSocket 读帧，分发处理
    while let Some(Ok(msg)) = ws_receiver.next().await {
        let data = match msg {
            Message::Binary(data) => data,
            Message::Close(_) => break,
            _ => continue,
        };
        let frame = match WsFrame::decode(data.as_ref()) {
            Ok(f) => f,
            Err(_) => continue,
        };

        let frame_type = WsFrameType::try_from(frame.r#type).unwrap_or(WsFrameType::Ping);
        match frame_type {
            WsFrameType::Ping => {
                let pong = WsFrame { r#type: WsFrameType::Pong as i32, payload: vec![] };
                state.ws_state.send_to_user(user_id, pong.encode_to_vec()).await;
            }
            WsFrameType::ChatMessage => {
                state.dispatcher.handle_chat_message(user_id, &frame.payload).await;
            }
            _ => {}
        }
    }

    // 清理
    state.ws_state.remove(user_id).await;
    send_task.abort();
    println!("❌ [im-ws] user {} disconnected", user_id);
}

async fn wait_for_auth(
    receiver: &mut futures::stream::SplitStream<WebSocket>,
) -> Option<i64> {
    while let Some(Ok(msg)) = receiver.next().await {
        if let Message::Binary(data) = msg {
            let frame = WsFrame::decode(data.as_ref()).ok()?;
            if frame.r#type != WsFrameType::Auth as i32 { return None; }
            let auth_req = AuthRequest::decode(frame.payload.as_slice()).ok()?;
            return verify_token(&auth_req.token).ok();
        }
    }
    None
}

async fn send_frame<M: ProstMessage>(
    sender: &mut futures::stream::SplitSink<WebSocket, Message>,
    frame_type: WsFrameType,
    msg: &M,
) -> Result<(), axum::Error> {
    let frame = WsFrame { r#type: frame_type as i32, payload: msg.encode_to_vec() };
    sender.send(Message::Binary(frame.encode_to_vec().into())).await
}
