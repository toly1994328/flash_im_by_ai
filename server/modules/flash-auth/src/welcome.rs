use sqlx::PgPool;

const WELCOME_MSG: &str = "你好！欢迎使用闪讯 IM，有任何问题可以在这里反馈 😊";
const TEAM_USER_ID: i64 = 100000000;

/// 为新用户创建与闪讯团队的欢迎会话并发送消息
pub async fn send_welcome(db: &PgPool, user_id: i64) -> Result<(), sqlx::Error> {
    // 1. 创建会话
    let (conv_id,): (sqlx::types::Uuid,) = sqlx::query_as(
        "INSERT INTO conversations (type, last_message_preview, last_message_at, created_at, updated_at)
         VALUES (0, $1, NOW(), NOW(), NOW()) RETURNING id"
    )
    .bind(WELCOME_MSG)
    .fetch_one(db)
    .await?;

    // 2. 添加成员（闪讯团队 + 新用户）
    sqlx::query(
        "INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2), ($1, $3)"
    )
    .bind(conv_id)
    .bind(TEAM_USER_ID)
    .bind(user_id)
    .execute(db)
    .await?;

    // 3. 初始化序列号
    sqlx::query(
        "INSERT INTO conversation_seq (conversation_id, current_seq) VALUES ($1, 1)"
    )
    .bind(conv_id)
    .execute(db)
    .await?;

    // 4. 插入欢迎消息（发送者是闪讯团队）
    sqlx::query(
        "INSERT INTO messages (conversation_id, sender_id, seq, type, content, created_at)
         VALUES ($1, $2, 1, 0, $3, NOW())"
    )
    .bind(conv_id)
    .bind(TEAM_USER_ID)
    .bind(WELCOME_MSG)
    .execute(db)
    .await?;

    println!("👋 已为用户 {} 发送欢迎消息（来自闪讯团队）", user_id);
    Ok(())
}
