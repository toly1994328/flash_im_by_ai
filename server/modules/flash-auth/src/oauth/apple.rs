use flash_core::AppError;
use jsonwebtoken::{decode, decode_header, Algorithm, DecodingKey, Validation};
use reqwest::Client;
use serde::Deserialize;
use std::time::Duration;

use super::{OAuthProvider, OAuthUserInfo};

pub struct AppleProvider {
    client: Client,
    bundle_id: String,
}

impl AppleProvider {
    pub fn from_env() -> Self {
        let bundle_id = std::env::var("APPLE_BUNDLE_ID")
            .expect("APPLE_BUNDLE_ID must be set");

        let client = Client::builder()
            .timeout(Duration::from_secs(10))
            .build()
            .expect("Failed to create HTTP client");

        Self { client, bundle_id }
    }
}

#[derive(Deserialize)]
struct JwksResponse {
    keys: Vec<JwkKey>,
}

#[derive(Deserialize)]
struct JwkKey {
    kid: String,
    n: String,
    e: String,
}

#[derive(Deserialize)]
struct AppleClaims {
    sub: String,
    email: Option<String>,
}

#[async_trait::async_trait]
impl OAuthProvider for AppleProvider {
    /// Apple 不需要换 token，直接验证 identity_token 的签名
    async fn exchange_token(&self, identity_token: &str) -> Result<String, AppError> {
        // 1. 解析 token header 获取 kid
        let header = decode_header(identity_token)
            .map_err(|e| AppError::bad_request(&format!("无效的 identity_token: {}", e)))?;

        let kid = header.kid
            .ok_or_else(|| AppError::bad_request("identity_token 缺少 kid"))?;

        // 2. 获取 Apple JWKS 公钥
        let resp = self.client
            .get("https://appleid.apple.com/auth/keys")
            .send()
            .await
            .map_err(|e| AppError::internal(e, "apple_fetch_jwks"))?;

        let jwks: JwksResponse = resp.json().await
            .map_err(|e| AppError::internal(e, "apple_parse_jwks"))?;

        // 3. 找到对应 kid 的公钥
        let key = jwks.keys.iter()
            .find(|k| k.kid == kid)
            .ok_or_else(|| AppError::bad_request("Apple JWKS 中未找到对应的公钥"))?;

        // 4. 构建解码密钥并验证签名
        let decoding_key = DecodingKey::from_rsa_components(&key.n, &key.e)
            .map_err(|e| AppError::internal(e, "apple_decoding_key"))?;

        let mut validation = Validation::new(Algorithm::RS256);
        validation.set_issuer(&["https://appleid.apple.com"]);
        validation.set_audience(&[&self.bundle_id]);

        decode::<serde_json::Value>(identity_token, &decoding_key, &validation)
            .map_err(|e| AppError::bad_request(&format!("identity_token 验证失败: {}", e)))?;

        // 验证通过，返回 token 本身供 get_user_info 解析
        Ok(identity_token.to_string())
    }

    /// 从已验证的 identity_token 中提取用户信息
    async fn get_user_info(&self, token: &str) -> Result<OAuthUserInfo, AppError> {
        // 不验证签名（exchange_token 已验证），只解码 payload
        let mut validation = Validation::new(Algorithm::RS256);
        validation.insecure_disable_signature_validation();
        validation.set_issuer(&["https://appleid.apple.com"]);
        validation.set_audience(&[&self.bundle_id]);

        let token_data = decode::<AppleClaims>(
            token,
            &DecodingKey::from_secret(b"unused"),
            &validation,
        ).map_err(|e| AppError::internal(e, "apple_decode_claims"))?;

        let claims = token_data.claims;
        let nickname = claims.email
            .as_ref()
            .map(|e| e.split('@').next().unwrap_or("Apple用户").to_string())
            .unwrap_or_else(|| "Apple用户".to_string());

        Ok(OAuthUserInfo {
            provider: "apple".to_string(),
            provider_id: claims.sub,
            nickname,
            avatar: None,
        })
    }
}
