mod mock;

use axum::Router;
use axum::routing::get;
use flash_core::state::create_app_state;
use flash_core::get_local_ip;
use im_ws::handler::ws_handler;
use sqlx::postgres::PgPoolOptions;
use tower_http::services::ServeDir;

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

    let state = create_app_state(db);
    let local_ip = get_local_ip();

    let app = Router::new()
        .merge(flash_auth::router())
        .merge(flash_user::router())
        .merge(mock::routes::router())
        .route("/ws/im", get(ws_handler))
        .nest_service("/static", ServeDir::new("static"))
        .with_state(state);

    println!("🚀 Flash IM server listening on:");
    println!("   Local:   http://127.0.0.1:{port}");
    println!("   Network: http://{local_ip}:{port}");

    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{port}"))
        .await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
