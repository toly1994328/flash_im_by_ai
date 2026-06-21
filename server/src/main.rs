mod mock;
mod admin;

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
use im_group::{GroupService, GroupApiState, group_routes};
use sqlx::postgres::PgPoolOptions;
use tower_http::services::{ServeDir, ServeFile};
use tower_http::compression::CompressionLayer;
use tower_http::set_header::SetResponseHeaderLayer;
use axum::http::{HeaderName, HeaderValue};
use app_storage::{LocalFs, StorageConfig, StorageService, OssBackend, OssConfig, StsConfig};
use app_storage::api::{storage_routes, oss_routes, OssRouteState};
use app_subscription::{SubscriptionService, subscription_routes};

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
    let dispatcher = Arc::new(MessageDispatcher::new(msg_service.clone(), ws_state.clone(), db.clone()));

    // WS handler 状态
    let ws_for_storage = ws_state.clone();
    let ws_for_subscription = ws_state.clone();
    let ws_handler_state = Arc::new(WsHandlerState {
        ws_state,
        dispatcher: dispatcher.clone(),
        db: db.clone(),
    });

    // 文件存储服务
    let storage_config = StorageConfig::from_env();
    let local_fs = LocalFs::new(storage_config.base_path.clone());
    let mut storage = StorageService::new(local_fs, storage_config, db.clone());

    // 配额变更时推 WS 通知
    storage.set_on_quota_changed(Arc::new(move |user_id, used_bytes, quota_bytes| {
        let ws = ws_for_storage.clone();
        tokio::spawn(async move {
            use im_ws::proto::{WsFrame, WsFrameType, StorageQuotaNotification};
            use prost::Message;
            let notification = StorageQuotaNotification { used_bytes, quota_bytes };
            let frame = WsFrame {
                r#type: WsFrameType::StorageQuotaUpdate as i32,
                payload: notification.encode_to_vec(),
            };
            ws.send_to_user(user_id, frame.encode_to_vec()).await;
        });
    }));
    let storage = Arc::new(storage);

    // OSS 后端（可选，仅当环境变量配置时启用）
    let oss_route_state = OssConfig::from_env().and_then(|oss_config| {
        let sts_config = StsConfig::from_env()?;
        let bucket = oss_config.bucket.clone();
        let endpoint = oss_config.endpoint.clone();
        let oss_backend = Arc::new(OssBackend::new(oss_config));
        println!("✅ [OSS] 已启用，bucket={}, endpoint={}", bucket, endpoint);
        Some(OssRouteState {
            oss: oss_backend,
            sts: Arc::new(sts_config),
            bucket,
            endpoint,
            db: db.clone(),
        })
    });

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

    // 群聊路由状态
    let group_api_state = GroupApiState {
        service: Arc::new(GroupService::new(db.clone())),
        msg_service: msg_service.clone(),
        dispatcher: dispatcher.clone(),
    };

    let app = Router::new()
        .merge(flash_auth::router())
        .merge(flash_user::router())
        .merge(mock::routes::router())
        .merge(im_conversation::router())
        .with_state(state)
        .merge(im_message::router(msg_service))
        .merge(storage_routes(storage))
        .merge(if let Some(oss_state) = oss_route_state { oss_routes(oss_state) } else { Router::new() })
        .merge(friend_routes(friend_state))
        .merge(group_routes(group_api_state))
        .merge(app_center::router(db.clone()))
        .merge({
            let mut sub_svc = SubscriptionService::new(db.clone());
            sub_svc.set_on_quota_changed(Arc::new(move |user_id, used_bytes, quota_bytes| {
                let ws = ws_for_subscription.clone();
                tokio::spawn(async move {
                    use im_ws::proto::{WsFrame, WsFrameType, StorageQuotaNotification};
                    use prost::Message;
                    let notification = StorageQuotaNotification { used_bytes, quota_bytes };
                    let frame = WsFrame {
                        r#type: WsFrameType::StorageQuotaUpdate as i32,
                        payload: notification.encode_to_vec(),
                    };
                    ws.send_to_user(user_id, frame.encode_to_vec()).await;
                });
            }));
            subscription_routes(Arc::new(sub_svc))
        })
        .merge(admin::router(db.clone()))
        .route("/ws/im", get(ws_handler).with_state(ws_handler_state))
        .nest_service("/static", ServeDir::new("static"))
        .nest_service("/im", ServeDir::new("static/im").fallback(ServeFile::new("static/im/index.html")))
        // Gzip/Brotli 压缩：JS/Wasm 文件压缩率 ~70%（不压缩 uploads，保留 Content-Length）
        .layer(CompressionLayer::new())
        .nest_service("/uploads", ServeDir::new("uploads"))
        // COOP/COEP 头：启用 SharedArrayBuffer，让 skwasm 多线程渲染生效
        .layer(SetResponseHeaderLayer::overriding(
            HeaderName::from_static("cross-origin-embedder-policy"),
            HeaderValue::from_static("credentialless"),
        ))
        .layer(SetResponseHeaderLayer::overriding(
            HeaderName::from_static("cross-origin-opener-policy"),
            HeaderValue::from_static("same-origin"),
        ));

    println!("🚀 Flash IM server listening on:");
    println!("   Local:   http://127.0.0.1:{port}");
    println!("   Network: http://{local_ip}:{port}");

    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{port}"))
        .await.unwrap();
    axum::serve(listener, app.into_make_service_with_connect_info::<std::net::SocketAddr>()).await.unwrap();
}
