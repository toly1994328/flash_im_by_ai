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

/// 扫码创建响应
#[derive(Serialize)]
pub struct ScanCreateResponse {
    pub token: String,
    pub qr_content: String,
    pub expires_at: chrono::DateTime<chrono::Utc>,
}

/// 扫码状态响应
#[derive(Serialize)]
pub struct ScanStatusResponse {
    pub status: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub token: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub user_id: Option<i64>,
}

/// 扫码确认请求
#[derive(Deserialize)]
pub struct ScanConfirmRequest {
    pub scan_token: String,
    pub action: String,
}

/// 扫码取消请求
#[derive(Deserialize)]
pub struct ScanCancelRequest {
    pub scan_token: String,
}
