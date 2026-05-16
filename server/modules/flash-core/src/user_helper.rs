use sqlx::PgPool;

/// 查询用户昵称，查不到时返回 "?"
pub async fn get_nickname(db: &PgPool, user_id: i64) -> String {
    sqlx::query_as::<_, (String,)>(
        "SELECT COALESCE(nickname, '?') FROM user_profiles WHERE account_id = $1",
    )
    .bind(user_id)
    .fetch_optional(db)
    .await
    .ok()
    .flatten()
    .map(|(n,)| n)
    .unwrap_or_else(|| "?".to_string())
}
