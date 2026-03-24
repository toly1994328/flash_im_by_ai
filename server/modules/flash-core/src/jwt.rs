use jsonwebtoken::{DecodingKey, Validation, decode};
use serde::{Deserialize, Serialize};
use std::sync::OnceLock;

/// 从环境变量读取 JWT_SECRET，整个进程生命周期只读一次
pub fn jwt_secret() -> &'static str {
    static SECRET: OnceLock<String> = OnceLock::new();
    SECRET.get_or_init(|| {
        std::env::var("JWT_SECRET")
            .unwrap_or_else(|_| "flash-im-dev-secret-change-in-production".into())
    })
}

#[derive(Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,
    pub exp: i64,
    pub iat: i64,
}

/// 验证 Token，返回 user_id
pub fn verify_token(token: &str) -> Result<i64, &'static str> {
    let secret = jwt_secret();
    let data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::default(),
    )
    .map_err(|_| "Token 无效")?;
    data.claims.sub.parse().map_err(|_| "用户 ID 解析失败")
}
