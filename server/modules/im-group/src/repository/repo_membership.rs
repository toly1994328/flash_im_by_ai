use uuid::Uuid;

use super::GroupRepository;

impl GroupRepository {
    /// 检查用户是否是群成员
    pub async fn is_member(
        &self,
        conversation_id: Uuid,
        user_id: i64,
    ) -> Result<bool, sqlx::Error> {
        let row: Option<(i32,)> = sqlx::query_as(
            "SELECT 1 FROM conversation_members WHERE conversation_id = $1 AND user_id = $2 AND is_deleted = false"
        )
        .bind(conversation_id)
        .bind(user_id)
        .fetch_optional(&self.db)
        .await?;
        Ok(row.is_some())
    }

    /// 邀请入群（批量添加成员）
    pub async fn add_members(
        &self,
        conversation_id: Uuid,
        member_ids: &[i64],
    ) -> Result<usize, sqlx::Error> {
        let mut added = 0usize;
        for &uid in member_ids {
            let result = sqlx::query(
                "INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2)
                 ON CONFLICT (conversation_id, user_id) DO UPDATE SET is_deleted = FALSE, joined_at = NOW()"
            )
            .bind(conversation_id)
            .bind(uid)
            .execute(&self.db)
            .await?;
            if result.rows_affected() > 0 {
                added += 1;
            }
        }

        let avatar = self.build_grid_avatar(conversation_id).await?;
        sqlx::query("UPDATE conversations SET avatar = $2 WHERE id = $1")
            .bind(conversation_id)
            .bind(&avatar)
            .execute(&self.db)
            .await?;

        Ok(added)
    }

    /// 移除群成员（踢人和退群共用）
    pub async fn remove_member(
        &self,
        conversation_id: Uuid,
        user_id: i64,
    ) -> Result<(), sqlx::Error> {
        sqlx::query(
            "UPDATE conversation_members SET is_deleted = TRUE WHERE conversation_id = $1 AND user_id = $2"
        )
        .bind(conversation_id)
        .bind(user_id)
        .execute(&self.db)
        .await?;

        let avatar = self.build_grid_avatar(conversation_id).await?;
        sqlx::query("UPDATE conversations SET avatar = $2 WHERE id = $1")
            .bind(conversation_id)
            .bind(&avatar)
            .execute(&self.db)
            .await?;

        Ok(())
    }
}
