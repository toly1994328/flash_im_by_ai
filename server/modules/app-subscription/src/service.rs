use std::sync::Arc;

use chrono::{DateTime, Utc};
use serde::Serialize;
use sqlx::PgPool;

use flash_core::AppError;
use crate::repository::SubRepo;

const BASE_QUOTA: i64 = 104_857_600; // 100MB

/// 兑换结果
#[derive(Debug, Serialize)]
pub struct RedeemResult {
    pub subscription: SubscriptionInfo,
    pub quota: QuotaInfo,
}

#[derive(Debug, Serialize)]
pub struct SubscriptionInfo {
    pub id: i32,
    pub plan_code: String,
    pub plan_name: String,
    pub status: String,
    pub starts_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
    pub storage_bytes: i64,
}

#[derive(Debug, Serialize)]
pub struct QuotaInfo {
    pub used_bytes: i64,
    pub quota_bytes: i64,
}

/// 订阅状态查询结果
#[derive(Debug, Serialize)]
pub struct SubscriptionStatus {
    pub has_active_subscription: bool,
    pub plan_code: Option<String>,
    pub plan_name: Option<String>,
    pub expires_at: Option<DateTime<Utc>>,
    pub oss_upload_enabled: bool,
    pub quota: QuotaInfo,
}

pub struct SubscriptionService {
    db: PgPool,
    on_quota_changed: Option<Arc<dyn Fn(i64, i64, i64) + Send + Sync>>,
}

impl SubscriptionService {
    pub fn new(db: PgPool) -> Self {
        Self { db, on_quota_changed: None }
    }

    /// 设置配额变更回调（main.rs 中注入 WS 通知）
    pub fn set_on_quota_changed(&mut self, callback: Arc<dyn Fn(i64, i64, i64) + Send + Sync>) {
        self.on_quota_changed = Some(callback);
    }

    /// 兑换码兑换
    pub async fn redeem(&self, user_id: i64, code: &str) -> Result<RedeemResult, AppError> {
        // 1. 查兑换码
        let redeem = SubRepo::find_redeem_code(&self.db, code).await?
            .ok_or_else(|| AppError::bad_request("兑换码无效"))?;

        // 2. 检查是否用完
        if redeem.used_count >= redeem.max_uses {
            return Err(AppError::bad_request("兑换码已用完"));
        }

        // 3. 检查是否过期
        if let Some(expires) = redeem.expires_at {
            if expires < Utc::now() {
                return Err(AppError::bad_request("兑换码已过期"));
            }
        }

        // 4. 查计划
        let plan = SubRepo::find_plan_by_id(&self.db, redeem.plan_id).await?
            .ok_or_else(|| AppError::bad_request("关联的订阅计划不存在"))?;

        // 5. 创建订阅
        let sub = SubRepo::create_subscription(
            &self.db, user_id, plan.id, redeem.duration_days, "redeem",
        ).await?;

        // 6. 兑换码 used_count +1
        SubRepo::increment_redeem_used(&self.db, redeem.id).await?;

        // 7. 重算配额
        let (used_bytes, quota_bytes) = self.recalculate_quota(user_id).await?;

        Ok(RedeemResult {
            subscription: SubscriptionInfo {
                id: sub.id,
                plan_code: plan.code,
                plan_name: plan.name,
                status: sub.status,
                starts_at: sub.starts_at,
                expires_at: sub.expires_at,
                storage_bytes: plan.storage_bytes,
            },
            quota: QuotaInfo { used_bytes, quota_bytes },
        })
    }

    /// 查询订阅状态
    pub async fn get_status(&self, user_id: i64) -> Result<SubscriptionStatus, AppError> {
        let active_sub = SubRepo::find_active_subscription(&self.db, user_id).await?;

        let (plan_code, plan_name, expires_at, oss_enabled) = if let Some(ref sub) = active_sub {
            let plan = SubRepo::find_plan_by_id(&self.db, sub.plan_id).await?;
            let oss = plan.as_ref()
                .and_then(|p| p.features.get("oss_upload"))
                .and_then(|v| v.as_bool())
                .unwrap_or(false);
            (
                plan.as_ref().map(|p| p.code.clone()),
                plan.as_ref().map(|p| p.name.clone()),
                Some(sub.expires_at),
                oss,
            )
        } else {
            (None, None, None, false)
        };

        // 配额
        let sub_storage = SubRepo::sum_active_storage(&self.db, user_id).await?;
        let quota_bytes = BASE_QUOTA + sub_storage;
        let used_bytes = self.get_used_bytes(user_id).await?;

        Ok(SubscriptionStatus {
            has_active_subscription: active_sub.is_some(),
            plan_code,
            plan_name,
            expires_at,
            oss_upload_enabled: oss_enabled,
            quota: QuotaInfo { used_bytes, quota_bytes },
        })
    }

    /// 重算配额并更新 user_storage_quota 表
    async fn recalculate_quota(&self, user_id: i64) -> Result<(i64, i64), AppError> {
        let sub_storage = SubRepo::sum_active_storage(&self.db, user_id).await?;
        let new_quota = BASE_QUOTA + sub_storage;

        // 更新 user_storage_quota.quota_bytes
        sqlx::query(
            "INSERT INTO user_storage_quota (user_id, used_bytes, quota_bytes, updated_at)
             VALUES ($1, 0, $2, NOW())
             ON CONFLICT (user_id) DO UPDATE SET quota_bytes = $2, updated_at = NOW()"
        )
            .bind(user_id)
            .bind(new_quota)
            .execute(&self.db)
            .await?;

        let used_bytes = self.get_used_bytes(user_id).await?;

        // 触发 WS 配额通知
        if let Some(ref cb) = self.on_quota_changed {
            cb(user_id, used_bytes, new_quota);
        }

        Ok((used_bytes, new_quota))
    }

    /// 获取用户已使用空间
    async fn get_used_bytes(&self, user_id: i64) -> Result<i64, AppError> {
        let row: Option<(i64,)> = sqlx::query_as(
            "SELECT used_bytes FROM user_storage_quota WHERE user_id = $1"
        )
            .bind(user_id)
            .fetch_optional(&self.db)
            .await?;
        Ok(row.map(|r| r.0).unwrap_or(0))
    }
}
