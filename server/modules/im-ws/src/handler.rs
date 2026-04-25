//! WebSocket 连接处理

use std::sync::Arc;
use axum::{
    extract::{ws::{Message, WebSocket, WebSocketUpgrade}, State},
    response::IntoResponse,
};
use futures::{SinkExt, StreamExt};
use prost::Message as ProstMessage;
use tokio::sync::mpsc;
use uuid::Uuid;

use flash_core::jwt::verify_token;

use crate::proto::{AuthRequest, AuthResult, ReadReceiptRequest, WsFrame, WsFrameType};
use crate::state::WsState;
use crate::dispatcher::MessageDispatcher;

pub struct WsHandlerState {
    pub ws_state: Arc<WsState>,
    pub dispatcher: Arc<MessageDispatcher>,
    pub db: sqlx::PgPool,
}

pub async fn ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<Arc<WsHandlerState>>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_socket(socket, state))
}

async fn handle_socket(socket: WebSocket, state: Arc<WsHandlerState>) {
    let conn_id = Uuid::new_v4().to_string();
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
    println!("✅ [im-ws] user {} connected (conn={})", user_id, &conn_id[..8]);

    // 创建推送通道，注册到在线用户表
    let (tx, mut rx) = mpsc::unbounded_channel::<Vec<u8>>();
    let is_first = state.ws_state.add(user_id, conn_id.clone(), tx).await;

    // 首次上线广播
    if is_first {
        state.dispatcher.broadcast_user_online(user_id).await;
    }

    // 推送在线列表
    state.dispatcher.send_online_list(user_id).await;

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
            WsFrameType::ReadReceipt => {
                handle_read_receipt(user_id, &frame.payload, &state).await;
            }
            _ => {}
        }
    }

    // 清理：移除连接，判断是否完全下线
    let is_last = state.ws_state.remove(user_id, &conn_id).await;
    send_task.abort();

    if is_last {
        state.dispatcher.broadcast_user_offline(user_id).await;
    }
    println!("❌ [im-ws] user {} disconnected (conn={}, last={})", user_id, &conn_id[..8], is_last);
}

/// 处理已读回执
async fn handle_read_receipt(user_id: i64, payload: &[u8], state: &WsHandlerState) {
    let req = match ReadReceiptRequest::decode(payload) {
        Ok(r) => r,
        Err(_) => return,
    };
    let conv_id = match Uuid::parse_str(&req.conversation_id) {
        Ok(id) => id,
        Err(_) => return,
    };

    // 1. 更新 last_read_seq（GREATEST 防止回退）
    let _ = sqlx::query(
        "UPDATE conversation_members \
         SET last_read_seq = GREATEST(last_read_seq, $3) \
         WHERE conversation_id = $1 AND user_id = $2"
    )
    .bind(conv_id)
    .bind(user_id)
    .bind(req.read_seq)
    .execute(&state.db)
    .await;

    // 2. 重新计算 unread_count
    let _ = sqlx::query(
        "UPDATE conversation_members cm \
         SET unread_count = ( \
             SELECT COUNT(*) FROM messages m \
             WHERE m.conversation_id = cm.conversation_id \
               AND m.seq > cm.last_read_seq \
               AND m.sender_id != cm.user_id \
         ) \
         WHERE cm.conversation_id = $1 AND cm.user_id = $2"
    )
    .bind(conv_id)
    .bind(user_id)
    .execute(&state.db)
    .await;

    // 3. 查询会话成员，推送已读通知给其他人
    let member_rows: Vec<(i64,)> = sqlx::query_as(
        "SELECT user_id FROM conversation_members \
         WHERE conversation_id = $1 AND is_deleted = false"
    )
    .bind(conv_id)
    .fetch_all(&state.db)
    .await
    .unwrap_or_default();

    let member_ids: Vec<i64> = member_rows.into_iter().map(|(id,)| id).collect();
    state.dispatcher.broadcast_read_receipt(
        &req.conversation_id, user_id, req.read_seq, &member_ids,
    ).await;
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
