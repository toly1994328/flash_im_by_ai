use axum::{
    Router,
    extract::ws::WebSocketUpgrade,
    extract::State,
    response::IntoResponse,
    routing::get,
};
use std::sync::Arc;

use crate::state::AppState;
use super::auth::handle_auth_socket;
use super::chat_room::handle_chat_room;
use super::handler::ws_handler;

/// GET /ws/auth — 需要认证的 WebSocket 端点
async fn ws_auth_handler(
    ws: WebSocketUpgrade,
    State(state): State<Arc<AppState>>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_auth_socket(socket, state))
}

/// GET /ws/chat_room — 聊天室 WebSocket 端点（需认证）
async fn ws_chat_room_handler(
    ws: WebSocketUpgrade,
    State(state): State<Arc<AppState>>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_chat_room(socket, state))
}

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/ws", get(ws_handler))
        .route("/ws/auth", get(ws_auth_handler))
        .route("/ws/chat_room", get(ws_chat_room_handler))
}
