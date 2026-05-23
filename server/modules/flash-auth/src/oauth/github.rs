use flash_core::AppError;
use reqwest::Client;
use serde::Deserialize;
use std::time::Duration;

use super::{OAuthProvider, OAuthUserInfo};

pub struct GitHubProvider {
    client: Client,
    client_id: String,
    client_secret: String,
}

impl GitHubProvider {
    pub fn from_env() -> Self {
        let client_id = std::env::var("GITHUB_CLIENT_ID")
            .expect("GITHUB_CLIENT_ID must be set");
        let client_secret = std::env::var("GITHUB_CLIENT_SECRET")
            .expect("GITHUB_CLIENT_SECRET must be set");

        let client = Client::builder()
            .timeout(Duration::from_secs(10))
            .build()
            .expect("Failed to create HTTP client");

        Self { client, client_id, client_secret }
    }
}

#[derive(Deserialize)]
struct TokenResponse {
    access_token: Option<String>,
    error: Option<String>,
    error_description: Option<String>,
}

#[derive(Deserialize)]
struct GitHubUser {
    id: i64,
    login: String,
    name: Option<String>,
    avatar_url: Option<String>,
}

#[async_trait::async_trait]
impl OAuthProvider for GitHubProvider {
    async fn exchange_token(&self, code: &str) -> Result<String, AppError> {
        let resp = self.client
            .post("https://github.com/login/oauth/access_token")
            .header("Accept", "application/json")
            .json(&serde_json::json!({
                "client_id": self.client_id,
                "client_secret": self.client_secret,
                "code": code,
            }))
            .send()
            .await
            .map_err(|e| AppError::internal(e, "github_exchange_token"))?;

        let token_resp: TokenResponse = resp.json().await
            .map_err(|e| AppError::internal(e, "github_parse_token"))?;

        if let Some(error) = token_resp.error {
            let desc = token_resp.error_description.unwrap_or_default();
            return Err(AppError::bad_request(&format!("GitHub OAuth 失败: {} - {}", error, desc)));
        }

        token_resp.access_token
            .ok_or_else(|| AppError::bad_request("GitHub 未返回 access_token"))
    }

    async fn get_user_info(&self, token: &str) -> Result<OAuthUserInfo, AppError> {
        let resp = self.client
            .get("https://api.github.com/user")
            .header("Authorization", format!("Bearer {}", token))
            .header("User-Agent", "flash-im")
            .send()
            .await
            .map_err(|e| AppError::internal(e, "github_get_user"))?;

        if !resp.status().is_success() {
            return Err(AppError::bad_request("GitHub token 无效或已过期"));
        }

        let user: GitHubUser = resp.json().await
            .map_err(|e| AppError::internal(e, "github_parse_user"))?;

        Ok(OAuthUserInfo {
            provider: "github".to_string(),
            provider_id: user.id.to_string(),
            nickname: user.name.unwrap_or(user.login),
            avatar: user.avatar_url,
        })
    }
}
