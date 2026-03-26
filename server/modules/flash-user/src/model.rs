use serde::{Deserialize, Serialize};

/// PUT /user/profile 请求体（字段均可选，只更新传入的）
#[derive(Deserialize)]
pub struct UpdateProfileRequest {
    pub nickname: Option<String>,
    pub avatar: Option<String>,
    pub signature: Option<String>,
}

/// POST /user/password 请求体（首次设置）
#[derive(Deserialize)]
pub struct SetPasswordRequest {
    pub new_password: String,
}

/// PUT /user/password 请求体（修改密码）
#[derive(Deserialize)]
pub struct ChangePasswordRequest {
    pub old_password: String,
    pub new_password: String,
}

/// 通用消息响应
#[derive(Serialize)]
pub struct MessageResponse {
    pub message: String,
}
