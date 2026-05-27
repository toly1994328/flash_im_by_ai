use serde::{Deserialize, Serialize};

/// 设备信息（登录时客户端携带）
#[derive(Deserialize, Default, Clone)]
pub struct DeviceInfo {
    pub platform: Option<String>,
    pub device_name: Option<String>,
    pub device_id: Option<String>,
    pub app_version: Option<String>,
}

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
    Email,
}

/// 统一登录请求，通过 type 区分登录方式
#[derive(Deserialize)]
pub struct LoginRequest {
    pub phone: String,
    #[serde(rename = "type")]
    pub login_type: LoginType,
    /// 验证码或密码
    pub credential: String,
    #[serde(default)]
    pub device_info: DeviceInfo,
}

/// OAuth 登录请求（GitHub / Google）
#[derive(Deserialize)]
pub struct OAuthLoginRequest {
    pub code: String,
    #[serde(default)]
    pub device_info: DeviceInfo,
}

/// Apple 登录请求
#[derive(Deserialize)]
pub struct AppleLoginRequest {
    pub identity_token: String,
    #[serde(default)]
    pub device_info: DeviceInfo,
}

/// 邮箱验证码请求
#[derive(Deserialize)]
pub struct EmailCodeRequest {
    pub email: String,
}

/// 邮箱验证码响应
#[derive(Serialize)]
pub struct EmailCodeResponse {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub code: Option<String>,
    pub message: String,
}

#[derive(Serialize)]
pub struct LoginResponse {
    pub token: String,
    pub user_id: i64,
    pub has_password: bool,
}
