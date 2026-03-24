use chrono::Utc;
use jsonwebtoken::{EncodingKey, Header, encode};
use flash_core::jwt::{Claims, jwt_secret};

/// 生成 Token（认证行为，只在 flash-auth 内部使用）
pub fn generate_token(user_id: i64) -> String {
    let secret = jwt_secret();
    let now = Utc::now().timestamp();
    let claims = Claims {
        sub: user_id.to_string(),
        exp: now + 7 * 24 * 3600,
        iat: now,
    };
    encode(&Header::default(), &claims, &EncodingKey::from_secret(secret.as_bytes())).unwrap()
}
