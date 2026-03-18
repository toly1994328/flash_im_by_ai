use axum::{
    extract::ws::{Message, WebSocket, WebSocketUpgrade},
    response::IntoResponse,
};
use futures::StreamExt;

/// GET /ws — WebSocket 升级端点
pub async fn ws_handler(ws: WebSocketUpgrade) -> impl IntoResponse {
    ws.on_upgrade(handle_socket)
}

/// 处理单个 WebSocket 连接
async fn handle_socket(mut socket: WebSocket) {
    println!("🔗 WebSocket 连接已建立");

    let welcome = "欢迎连接 Flash IM WebSocket 服务！";
    let _ = socket.send(Message::Text(welcome.into())).await;

    while let Some(Ok(msg)) = socket.next().await {
        match msg {
            Message::Text(text) => {
                println!("📨 收到文本: {text}");
                let reply = format!("echo: {text}");
                if socket.send(Message::Text(reply.into())).await.is_err() {
                    break;
                }
            }
            Message::Close(_) => break,
            _ => {}
        }
    }

    println!("❌ WebSocket 连接已断开");
}
