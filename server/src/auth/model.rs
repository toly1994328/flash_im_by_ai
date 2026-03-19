use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
pub struct SmsRequest {
    pub phone: String,
}

#[derive(Serialize)]
pub struct SmsResponse {
    pub code: String,
    pub message: String,
}

/// 登录方式
#[derive(Deserialize, Debug)]
#[serde(rename_all = "snake_case")]
pub enum LoginType {
    Sms,
    Password,
}

/// 统一登录请求，通过 type 区分登录方式
#[derive(Deserialize)]
pub struct LoginRequest {
    pub phone: String,
    #[serde(rename = "type")]
    pub login_type: LoginType,
    /// 验证码或密码
    pub credential: String,
}

#[derive(Serialize)]
pub struct LoginResponse {
    pub token: String,
    pub user_id: i64,
}
