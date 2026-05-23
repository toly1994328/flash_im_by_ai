use sqlx::PgPool;

use crate::model::DeviceInfo;

/// 记录一次登录日志
pub async fn record_login(
    db: &PgPool,
    account_id: i64,
    ip: Option<&str>,
    device_info: &DeviceInfo,
) -> Result<(), sqlx::Error> {
    sqlx::query(
        "INSERT INTO login_logs (account_id, ip, platform, device_name, device_id, app_version)
         VALUES ($1, $2, $3, $4, $5, $6)"
    )
    .bind(account_id)
    .bind(ip)
    .bind(device_info.platform.as_deref())
    .bind(device_info.device_name.as_deref())
    .bind(device_info.device_id.as_deref())
    .bind(device_info.app_version.as_deref())
    .execute(db)
    .await?;

    Ok(())
}

/// 判断是否首次登录（login_logs 中无记录）
pub async fn is_first_login(db: &PgPool, account_id: i64) -> Result<bool, sqlx::Error> {
    let exists: Option<(i32,)> = sqlx::query_as(
        "SELECT 1 FROM login_logs WHERE account_id = $1 LIMIT 1"
    )
    .bind(account_id)
    .fetch_optional(db)
    .await?;

    Ok(exists.is_none())
}
