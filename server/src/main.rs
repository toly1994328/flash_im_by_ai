mod mock;
mod group_routes;

use std::sync::Arc;
use axum::Router;
use axum::routing::get;
use flash_core::state::create_app_state;
use flash_core::get_local_ip;
use im_ws::handler::{ws_handler, WsHandlerState};
use im_ws::state::WsState;
use im_ws::broadcaster::WsBroadcaster;
use im_ws::dispatcher::MessageDispatcher;
use im_friend::{FriendRepository, FriendService, FriendApiState, friend_routes};
use group_routes::{GroupApiState, group_routes};
use sqlx::postgres::PgPoolOptions;
use tower_http::services::ServeDir;
use app_storage::{StorageConfig, StorageService};
use app_storage::api::storage_routes;

#[tokio::main]
async fn main() {
    dotenvy::dotenv().ok();

    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set in .env");
    let port: u16 = std::env::var("SERVER_PORT")
        .unwrap_or_else(|_| "9600".into())
        .parse()
        .expect("SERVER_PORT must be a valid port number");

    let db = PgPoolOptions::new()
        .max_connections(10)
        .connect(&database_url)
        .await
        .expect("Failed to connect to database");

    println!("✅ Database connected");

    let state = create_app_state(db.clone());
    let local_ip = get_local_ip();

    // WebSocket 状态
    let ws_state = Arc::new(WsState::new());

    // 广播器（依赖 ws_state）
    let broadcaster = Arc::new(WsBroadcaster::new(ws_state.clone(), db.clone()));

    // 消息服务（依赖 broadcaster）
    let msg_service = Arc::new(im_message::MessageService::new(db.clone(), broadcaster));

    // 消息分发器（依赖 msg_service + ws_state）
    let dispatcher = Arc::new(MessageDispatcher::new(msg_service.clone(), ws_state.clone()));

    // WS handler 状态
    let ws_handler_state = Arc::new(WsHandlerState {
        ws_state,
        dispatcher: dispatcher.clone(),
    });

    // 文件存储服务
    let storage = Arc::new(StorageService::new(StorageConfig::from_env()));

    // 好友服务
    let friend_repo = Arc::new(FriendRepository::new(db.clone()));
    let friend_service = Arc::new(FriendService::new(friend_repo));
    let conv_service_for_friend = Arc::new(im_conversation::ConversationService::new(db.clone()));
    let friend_state = FriendApiState {
        service: friend_service,
        dispatcher: Some(dispatcher.clone()),
        conv_service: Some(conv_service_for_friend),
        msg_service: Some(msg_service.clone()),
    };

    // 群聊路由状态（需要 dispatcher）
    let group_api_state = GroupApiState {
        service: Arc::new(im_conversation::ConversationService::new(db.clone())),
        dispatcher: dispatcher.clone(),
        msg_service: msg_service.clone(),
    };

    let app = Router::new()
        .merge(flash_auth::router())
        .merge(flash_user::router())
        .merge(mock::routes::router())
        .merge(im_conversation::router())
        .with_state(state)
        .merge(im_message::router(msg_service))
        .merge(storage_routes(storage))
        .merge(friend_routes(friend_state))
        .merge(group_routes(group_api_state))
        .route("/ws/im", get(ws_handler).with_state(ws_handler_state))
        .nest_service("/uploads", ServeDir::new("uploads"))
        .nest_service("/static", ServeDir::new("static"));

    println!("🚀 Flash IM server listening on:");
    println!("   Local:   http://127.0.0.1:{port}");
    println!("   Network: http://{local_ip}:{port}");

    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{port}"))
        .await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
