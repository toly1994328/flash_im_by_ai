pub mod github;
pub mod apple;

use flash_core::AppError;
use sqlx::PgPool;

/// 第三方登录提供商返回的用户信息
pub struct OAuthUserInfo {
    pub provider: String,
    pub provider_id: String,
    pub nickname: String,
    pub avatar: Option<String>,
}

/// 第三方登录提供商接口
#[async_trait::async_trait]
pub trait OAuthProvider: Send + Sync {
    /// 用授权码换取 access_token
    async fn exchange_token(&self, code: &str) -> Result<String, AppError>;
    /// 用 token 获取用户信息
    async fn get_user_info(&self, token: &str) -> Result<OAuthUserInfo, AppError>;
}

/// 根据 OAuth 用户信息查找或创建账号
/// 返回 (account_id, is_new_user)
pub async fn find_or_create_by_oauth(
    db: &PgPool,
    info: &OAuthUserInfo,
) -> Result<(i64, bool), AppError> {
    // 查找已有账号
    let existing: Option<(i64,)> = sqlx::query_as(
        "SELECT account_id FROM auth_credentials WHERE auth_type = $1 AND identifier = $2"
    )
    .bind(&info.provider)
    .bind(&info.provider_id)
    .fetch_optional(db)
    .await?;

    if let Some((account_id,)) = existing {
        return Ok((account_id, false));
    }

    // 新用户：事务内创建
    let mut tx = db.begin().await?;

    let (account_id,): (i64,) = sqlx::query_as(
        "INSERT INTO accounts (status, created_at, updated_at) VALUES (0, NOW(), NOW()) RETURNING id"
    )
    .fetch_one(&mut *tx)
    .await?;

    let avatar = info.avatar.clone().unwrap_or_else(|| format!("identicon:{}", account_id));

    sqlx::query(
        "INSERT INTO user_profiles (account_id, nickname, avatar, updated_at) VALUES ($1, $2, $3, NOW())"
    )
    .bind(account_id)
    .bind(&info.nickname)
    .bind(&avatar)
    .execute(&mut *tx)
    .await?;

    sqlx::query(
        "INSERT INTO auth_credentials (account_id, auth_type, identifier, verified, created_at) VALUES ($1, $2, $3, true, NOW())"
    )
    .bind(account_id)
    .bind(&info.provider)
    .bind(&info.provider_id)
    .execute(&mut *tx)
    .await?;

    tx.commit().await?;

    println!("🆕 新用户注册({}): {} (ID: {})", info.provider, info.nickname, account_id);
    Ok((account_id, true))
}
