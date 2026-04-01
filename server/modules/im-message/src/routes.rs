use axum::{
    Router, Json,
    extract::{Path, State, Query},
    http::{HeaderMap, StatusCode},
    routing::get,
};
use std::sync::Arc;
use uuid::Uuid;

use flash_core::jwt::extract_user_id;

use crate::models::MessageQuery;
use crate::service::MessageService;

async fn get_messages(
    State(service): State<Arc<MessageService>>,
    headers: HeaderMap,
    Path(conversation_id): Path<String>,
    Query(query): Query<MessageQuery>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let _user_id = extract_user_id(&headers)?;
    let conv_id = Uuid::parse_str(&conversation_id)
        .map_err(|_| StatusCode::BAD_REQUEST)?;

    let messages = service.get_history(conv_id, query.before_seq, query.limit).await?;
    Ok(Json(serde_json::to_value(messages).unwrap()))
}

pub fn router(service: Arc<MessageService>) -> Router {
    Router::new()
        .route("/conversations/{id}/messages", get(get_messages))
        .with_state(service)
}
