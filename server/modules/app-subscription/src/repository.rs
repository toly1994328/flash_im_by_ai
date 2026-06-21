use chrono::{Duration, Utc};
use sqlx::PgPool;

use crate::model::{RedeemCode, SubscriptionPlan, UserSubscription};

pub struct SubRepo;

impl SubRepo {
    /// 查询兑换码
    pub async fn find_redeem_code(db: &PgPool, code: &str) -> Result<Option<RedeemCode>, sqlx::Error> {
        sqlx::query_as::<_, RedeemCode>("SELECT * FROM redeem_codes WHERE code = $1")
            .bind(code)
            .fetch_optional(db)
            .await
    }

    /// 兑换码 used_count +1
    pub async fn increment_redeem_used(db: &PgPool, code_id: i32) -> Result<(), sqlx::Error> {
        sqlx::query("UPDATE redeem_codes SET used_count = used_count + 1 WHERE id = $1")
            .bind(code_id)
            .execute(db)
            .await?;
        Ok(())
    }

    /// 查询计划
    pub async fn find_plan_by_id(db: &PgPool, plan_id: i32) -> Result<Option<SubscriptionPlan>, sqlx::Error> {
        sqlx::query_as::<_, SubscriptionPlan>("SELECT * FROM subscription_plans WHERE id = $1")
            .bind(plan_id)
            .fetch_optional(db)
            .await
    }

    /// 创建用户订阅
    pub async fn create_subscription(
        db: &PgPool,
        user_id: i64,
        plan_id: i32,
        duration_days: i32,
        source: &str,
    ) -> Result<UserSubscription, sqlx::Error> {
        let now = Utc::now();
        let expires_at = now + Duration::days(duration_days as i64);

        sqlx::query_as::<_, UserSubscription>(
            "INSERT INTO user_subscriptions (user_id, plan_id, status, starts_at, expires_at, source, created_at, updated_at)
             VALUES ($1, $2, 'active', $3, $4, $5, $3, $3)
             RETURNING *"
        )
            .bind(user_id)
            .bind(plan_id)
            .bind(now)
            .bind(expires_at)
            .bind(source)
            .fetch_one(db)
            .await
    }

    /// 查询用户活跃订阅（最近到期的一个）
    pub async fn find_active_subscription(db: &PgPool, user_id: i64) -> Result<Option<UserSubscription>, sqlx::Error> {
        sqlx::query_as::<_, UserSubscription>(
            "SELECT * FROM user_subscriptions
             WHERE user_id = $1 AND status = 'active' AND expires_at > NOW()
             ORDER BY expires_at DESC LIMIT 1"
        )
            .bind(user_id)
            .fetch_optional(db)
            .await
    }

    /// 计算用户所有活跃订阅的总配额
    pub async fn sum_active_storage(db: &PgPool, user_id: i64) -> Result<i64, sqlx::Error> {
        let row: (i64,) = sqlx::query_as(
            "SELECT COALESCE(SUM(p.storage_bytes)::BIGINT, 0::BIGINT)
             FROM user_subscriptions s
             JOIN subscription_plans p ON s.plan_id = p.id
             WHERE s.user_id = $1 AND s.status = 'active' AND s.expires_at > NOW()"
        )
            .bind(user_id)
            .fetch_one(db)
            .await?;
        Ok(row.0)
    }
}
