use axum::{
    Router, Json,
    extract::{State, Path, Query},
    http::{HeaderMap, StatusCode},
    routing::{post, get, put},
};
use std::sync::Arc;
use uuid::Uuid;

use flash_core::jwt::extract_user_id;
use im_message::MessageService;
use im_ws::dispatcher::MessageDispatcher;

use super::models::{
    CreateGroupRequest, SearchQuery, JoinGroupRequest, HandleJoinRequest,
    JoinGroupResponse, GroupSearchResult, JoinRequestItem, JoinResult,
    GroupDetail, UpdateGroupSettingsRequest,
};
use super::service::GroupService;

#[derive(Clone)]
pub struct GroupApiState {
    pub service: Arc<GroupService>,
    pub msg_service: Arc<MessageService>,
    pub dispatcher: Arc<MessageDispatcher>,
}

/// POST /groups — 创建群聊
async fn create_group(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Json(req): Json<CreateGroupRequest>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;

    let conv = state.service.create_group(user_id, &req.name, &req.member_ids).await?;

    // 发送系统消息 "XXX 创建了群聊"
    let creator_name: String = sqlx::query_as::<_, (String,)>(
        "SELECT COALESCE(nickname, '?') FROM user_profiles WHERE account_id = $1"
    )
    .bind(user_id)
    .fetch_optional(state.service.db())
    .await
    .ok()
    .flatten()
    .map(|(n,)| n)
    .unwrap_or_else(|| "?".to_string());

    let _ = state.msg_service.send_system(
        conv.id,
        format!("{} 创建了群聊", creator_name),
    ).await;

    Ok(Json(serde_json::to_value(conv).unwrap()))
}

/// GET /groups/search — 搜索群聊
async fn search_groups(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Query(query): Query<SearchQuery>,
) -> Result<Json<Vec<GroupSearchResult>>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let keyword = query.keyword.unwrap_or_default();
    let results = state.service.search_groups(user_id, &keyword).await?;
    Ok(Json(results))
}

/// POST /groups/{id}/join — 申请入群
async fn join_group(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Path(conv_id): Path<Uuid>,
    Json(req): Json<JoinGroupRequest>,
) -> Result<Json<JoinGroupResponse>, StatusCode> {
    let user_id = extract_user_id(&headers)?;

    let result = state.service.join_group(user_id, conv_id, req.message.as_deref()).await?;

    match result {
        JoinResult::AutoApproved => {
            // 发系统消息 "XXX 加入了群聊"
            let joiner_name: String = sqlx::query_as::<_, (String,)>(
                "SELECT COALESCE(nickname, '?') FROM user_profiles WHERE account_id = $1"
            )
            .bind(user_id)
            .fetch_optional(state.service.db())
            .await
            .ok()
            .flatten()
            .map(|(n,)| n)
            .unwrap_or_else(|| "?".to_string());

            let _ = state.msg_service.send_system(
                conv_id,
                format!("{} 加入了群聊", joiner_name),
            ).await;

            Ok(Json(JoinGroupResponse { auto_approved: true }))
        }
        JoinResult::PendingApproval { request_id, owner_id } => {
            // 异步推送 WS 通知给群主
            let dispatcher = state.dispatcher.clone();
            let db = state.service.db().clone();
            let req_id_str = request_id.to_string();
            let conv_id_str = conv_id.to_string();
            let message = req.message.clone();

            tokio::spawn(async move {
                // 查申请者信息
                let (nickname, avatar): (String, Option<String>) = sqlx::query_as(
                    "SELECT COALESCE(nickname, '?'), avatar FROM user_profiles WHERE account_id = $1"
                )
                .bind(user_id)
                .fetch_optional(&db)
                .await
                .ok()
                .flatten()
                .unwrap_or(("?".to_string(), None));

                // 查群名
                let group_name: String = sqlx::query_as::<_, (Option<String>,)>(
                    "SELECT name FROM conversations WHERE id = $1"
                )
                .bind(conv_id)
                .fetch_optional(&db)
                .await
                .ok()
                .flatten()
                .and_then(|(n,)| n)
                .unwrap_or_default();

                let now = chrono::Utc::now().timestamp_millis();
                dispatcher.notify_group_join_request(
                    owner_id,
                    &req_id_str,
                    &conv_id_str,
                    &group_name,
                    user_id,
                    &nickname,
                    avatar.as_deref(),
                    message.as_deref(),
                    now,
                ).await;
            });

            Ok(Json(JoinGroupResponse { auto_approved: false }))
        }
    }
}

/// POST /groups/{id}/join-requests/{rid}/handle — 群主审批
async fn handle_join_request(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Path((conv_id, request_id)): Path<(Uuid, Uuid)>,
    Json(req): Json<HandleJoinRequest>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;

    let result = state.service.handle_join_request(user_id, conv_id, request_id, req.approved).await?;

    // 如果同意，发系统消息
    if let Some(applicant_id) = result {
        let applicant_name: String = sqlx::query_as::<_, (String,)>(
            "SELECT COALESCE(nickname, '?') FROM user_profiles WHERE account_id = $1"
        )
        .bind(applicant_id)
        .fetch_optional(state.service.db())
        .await
        .ok()
        .flatten()
        .map(|(n,)| n)
        .unwrap_or_else(|| "?".to_string());

        let _ = state.msg_service.send_system(
            conv_id,
            format!("{} 加入了群聊", applicant_name),
        ).await;
    }

    Ok(Json(serde_json::json!({ "success": true })))
}

/// GET /groups/join-requests — 查询入群申请列表
async fn list_join_requests(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
) -> Result<Json<Vec<JoinRequestItem>>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let requests = state.service.list_join_requests(user_id).await?;
    Ok(Json(requests))
}

/// GET /groups/{id}/detail — 群详情
async fn get_group_detail(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Path(conv_id): Path<Uuid>,
) -> Result<Json<GroupDetail>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let detail = state.service.get_group_detail(user_id, conv_id).await?;
    Ok(Json(detail))
}

/// PUT /groups/{id}/settings — 群主修改群设置
async fn update_group_settings(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Path(conv_id): Path<Uuid>,
    Json(req): Json<UpdateGroupSettingsRequest>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    if let Some(jv) = req.join_verification {
        state.service.update_group_settings(user_id, conv_id, jv).await?;
    }
    Ok(Json(serde_json::json!({ "success": true })))
}

pub fn group_routes(state: GroupApiState) -> Router {
    Router::new()
        .route("/groups", post(create_group))
        .route("/groups/search", get(search_groups))
        .route("/groups/{id}/join", post(join_group))
        .route("/groups/{id}/join-requests/{rid}/handle", post(handle_join_request))
        .route("/groups/join-requests", get(list_join_requests))
        .route("/groups/{id}/detail", get(get_group_detail))
        .route("/groups/{id}/settings", put(update_group_settings))
        .with_state(state)
}
