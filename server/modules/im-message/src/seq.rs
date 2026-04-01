use sqlx::PgPool;
use uuid::Uuid;

pub struct SeqGenerator {
    pool: PgPool,
}

impl SeqGenerator {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// 获取下一个序列号（原子递增）
    pub async fn next(&self, conversation_id: Uuid) -> Result<i64, sqlx::Error> {
        let result: Option<(i64,)> = sqlx::query_as(
            "UPDATE conversation_seq SET current_seq = current_seq + 1 \
             WHERE conversation_id = $1 RETURNING current_seq",
        )
        .bind(conversation_id)
        .fetch_optional(&self.pool)
        .await?;

        match result {
            Some((seq,)) => Ok(seq),
            None => {
                let (seq,): (i64,) = sqlx::query_as(
                    "INSERT INTO conversation_seq (conversation_id, current_seq) \
                     VALUES ($1, 1) \
                     ON CONFLICT (conversation_id) \
                     DO UPDATE SET current_seq = conversation_seq.current_seq + 1 \
                     RETURNING current_seq",
                )
                .bind(conversation_id)
                .fetch_one(&self.pool)
                .await?;
                Ok(seq)
            }
        }
    }
}
