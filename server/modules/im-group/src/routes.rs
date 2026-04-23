use axum::{
    Router, Json,
    extract::{State, Path, Query},
    http::{HeaderMap, StatusCode},
    routing::{post, get, put, delete},
};
use std::sync::Arc;
use uuid::Uuid;

use flash_core::jwt::extract_user_id;
use flash_core::AppError;
use im_message::MessageService;
use im_ws::dispatcher::MessageDispatcher;

use super::models::{
    CreateGroupRequest, SearchQuery, JoinGroupRequest, HandleJoinRequest,
    JoinGroupResponse, GroupSearchResult, JoinRequestItem, JoinResult,
    GroupDetail, UpdateGroupSettingsRequest,
    AddMembersRequest, TransferOwnerRequest, UpdateGroupRequest, UpdateAnnouncementRequest,
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

// ─── v0.0.3：群成员管理 ───

/// POST /groups/{id}/members — 邀请入群
async fn add_members(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Path(conv_id): Path<Uuid>,
    Json(req): Json<AddMembersRequest>,
) -> Result<Json<serde_json::Value>, AppError> {
    let user_id = extract_user_id(&headers)?;

    let added_count = state.service.add_members(user_id, conv_id, &req.member_ids).await?;

    // 查邀请者昵称
    let inviter_name: String = sqlx::query_as::<_, (String,)>(
        "SELECT COALESCE(nickname, '?') FROM user_profiles WHERE account_id = $1"
    )
    .bind(user_id)
    .fetch_optional(state.service.db())
    .await
    .ok()
    .flatten()
    .map(|(n,)| n)
    .unwrap_or_else(|| "?".to_string());

    // 查被邀请者昵称
    let mut invited_names = Vec::new();
    for &mid in &req.member_ids {
        let name: String = sqlx::query_as::<_, (String,)>(
            "SELECT COALESCE(nickname, '?') FROM user_profiles WHERE account_id = $1"
        )
        .bind(mid)
        .fetch_optional(state.service.db())
        .await
        .ok()
        .flatten()
        .map(|(n,)| n)
        .unwrap_or_else(|| "?".to_string());
        invited_names.push(name);
    }

    let _ = state.msg_service.send_system(
        conv_id,
        format!("{} 邀请了 {} 加入群聊", inviter_name, invited_names.join("、")),
    ).await;

    Ok(Json(serde_json::json!({ "success": true, "added_count": added_count })))
}

/// DELETE /groups/{id}/members/{uid} — 踢人
async fn remove_member_handler(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Path((conv_id, target_id)): Path<(Uuid, i64)>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;

    state.service.remove_member(user_id, conv_id, target_id).await?;

    // 查被踢者昵称
    let target_name: String = sqlx::query_as::<_, (String,)>(
        "SELECT COALESCE(nickname, '?') FROM user_profiles WHERE account_id = $1"
    )
    .bind(target_id)
    .fetch_optional(state.service.db())
    .await
    .ok()
    .flatten()
    .map(|(n,)| n)
    .unwrap_or_else(|| "?".to_string());

    let _ = state.msg_service.send_system(
        conv_id,
        format!("{} 被移出群聊", target_name),
    ).await;

    Ok(Json(serde_json::json!({ "success": true })))
}

/// POST /groups/{id}/leave — 退群
async fn leave(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Path(conv_id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;

    // 先查昵称（退群后可能查不到成员关系）
    let leaver_name: String = sqlx::query_as::<_, (String,)>(
        "SELECT COALESCE(nickname, '?') FROM user_profiles WHERE account_id = $1"
    )
    .bind(user_id)
    .fetch_optional(state.service.db())
    .await
    .ok()
    .flatten()
    .map(|(n,)| n)
    .unwrap_or_else(|| "?".to_string());

    state.service.leave(user_id, conv_id).await?;

    let _ = state.msg_service.send_system(
        conv_id,
        format!("{} 退出了群聊", leaver_name),
    ).await;

    Ok(Json(serde_json::json!({ "success": true })))
}

/// PUT /groups/{id}/transfer — 转让群主
async fn transfer_owner(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Path(conv_id): Path<Uuid>,
    Json(req): Json<TransferOwnerRequest>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;

    state.service.transfer_owner(user_id, conv_id, req.new_owner_id).await?;

    // 查两人昵称
    let old_owner_name: String = sqlx::query_as::<_, (String,)>(
        "SELECT COALESCE(nickname, '?') FROM user_profiles WHERE account_id = $1"
    )
    .bind(user_id)
    .fetch_optional(state.service.db())
    .await
    .ok()
    .flatten()
    .map(|(n,)| n)
    .unwrap_or_else(|| "?".to_string());

    let new_owner_name: String = sqlx::query_as::<_, (String,)>(
        "SELECT COALESCE(nickname, '?') FROM user_profiles WHERE account_id = $1"
    )
    .bind(req.new_owner_id)
    .fetch_optional(state.service.db())
    .await
    .ok()
    .flatten()
    .map(|(n,)| n)
    .unwrap_or_else(|| "?".to_string());

    let _ = state.msg_service.send_system(
        conv_id,
        format!("{} 将群主转让给了 {}", old_owner_name, new_owner_name),
    ).await;

    Ok(Json(serde_json::json!({ "success": true })))
}

/// POST /groups/{id}/disband — 解散群聊
async fn disband(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Path(conv_id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;

    // 先发系统消息（解散后就发不了了）
    // 但需要先校验权限，所以先查群主
    let owner_id = sqlx::query_as::<_, (Option<i64>,)>(
        "SELECT owner_id FROM conversations WHERE id = $1 AND type = 1"
    )
    .bind(conv_id)
    .fetch_optional(state.service.db())
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?
    .0
    .ok_or(StatusCode::NOT_FOUND)?;

    if owner_id != user_id {
        return Err(StatusCode::FORBIDDEN);
    }

    // 先发系统消息
    let _ = state.msg_service.send_system(
        conv_id,
        "群聊已解散".to_string(),
    ).await;

    // 再解散
    state.service.disband(user_id, conv_id).await?;

    Ok(Json(serde_json::json!({ "success": true })))
}

/// PUT /groups/{id}/announcement — 更新群公告
async fn update_announcement(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Path(conv_id): Path<Uuid>,
    Json(req): Json<UpdateAnnouncementRequest>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    state.service.update_announcement(user_id, conv_id, &req.announcement).await?;

    // 发系统消息通知群成员
    let updater_name: String = sqlx::query_as::<_, (String,)>(
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
        format!("{} 更新了群公告", updater_name),
    ).await;

    // 推送 GROUP_INFO_UPDATE 给所有成员
    {
        let conv_id_str = conv_id.to_string();
        let announcement = req.announcement.clone();
        let member_ids = state.service.repo().get_member_ids(conv_id).await.unwrap_or_default();
        let dispatcher = state.dispatcher.clone();
        tokio::spawn(async move {
            dispatcher.notify_group_info_update(
                &member_ids,
                &conv_id_str,
                None,
                None,
                Some(&announcement),
                None,
            ).await;
        });
    }

    Ok(Json(serde_json::json!({ "success": true })))
}

/// PUT /groups/{id} — 修改群信息
async fn update_group(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Path(conv_id): Path<Uuid>,
    Json(req): Json<UpdateGroupRequest>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let new_name = req.name.clone();
    state.service.update_group(user_id, conv_id, req.name.as_deref(), req.avatar.as_deref()).await?;

    // 修改群名时发系统消息
    if let Some(ref name) = new_name {
        let updater_name: String = sqlx::query_as::<_, (String,)>(
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
            format!("{} 将群名修改为「{}」", updater_name, name),
        ).await;
    }

    // 推送 GROUP_INFO_UPDATE 给所有成员
    {
        let conv_id_str = conv_id.to_string();
        let member_ids = state.service.repo().get_member_ids(conv_id).await.unwrap_or_default();
        let dispatcher = state.dispatcher.clone();
        tokio::spawn(async move {
            dispatcher.notify_group_info_update(
                &member_ids,
                &conv_id_str,
                req.name.as_deref(),
                req.avatar.as_deref(),
                None,
                None,
            ).await;
        });
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
        .route("/groups/{id}/members", post(add_members))
        .route("/groups/{id}/members/{uid}", delete(remove_member_handler))
        .route("/groups/{id}/leave", post(leave))
        .route("/groups/{id}/transfer", put(transfer_owner))
        .route("/groups/{id}/disband", post(disband))
        .route("/groups/{id}/announcement", put(update_announcement))
        .route("/groups/{id}", put(update_group))
        .with_state(state)
}
