mod state;
mod auth;
mod ws;
mod mock;
mod util;

use axum::Router;
use tower_http::services::ServeDir;

#[tokio::main]
async fn main() {
    let state = state::create_app_state();
    let local_ip = util::network::get_local_ip();

    let app = Router::new()
        .merge(auth::routes::router())
        .merge(ws::routes::router())
        .merge(mock::routes::router())
        .nest_service("/static", ServeDir::new("static"))
        .with_state(state);

    let port = 9600;
    println!("🚀 Flash IM server listening on:");
    println!("   Local:   http://127.0.0.1:{port}");
    println!("   Network: http://{local_ip}:{port}");

    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{port}")).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
