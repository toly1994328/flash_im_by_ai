use chrono::{DateTime, Utc};
use serde::Serialize;

#[derive(Debug, Clone, sqlx::FromRow, Serialize)]
pub struct SubscriptionPlan {
    pub id: i32,
    pub code: String,
    pub name: String,
    pub storage_bytes: i64,
    pub features: serde_json::Value,
    pub price_cents: i32,
    pub period_days: i32,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, sqlx::FromRow, Serialize)]
pub struct UserSubscription {
    pub id: i32,
    pub user_id: i64,
    pub plan_id: i32,
    pub status: String,
    pub starts_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
    pub source: String,
    pub original_transaction_id: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct RedeemCode {
    pub id: i32,
    pub code: String,
    pub plan_id: i32,
    pub duration_days: i32,
    pub max_uses: i32,
    pub used_count: i32,
    pub expires_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
}
