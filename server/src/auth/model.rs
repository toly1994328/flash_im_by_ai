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

#[derive(Deserialize)]
pub struct LoginRequest {
    pub phone: String,
    pub code: String,
}

#[derive(Serialize)]
pub struct LoginResponse {
    pub token: String,
    pub user_id: i64,
}
