use uuid::Uuid;

use super::GroupRepository;

impl GroupRepository {
    /// 更新群设置
    pub async fn update_group_settings(
        &self,
        conversation_id: Uuid,
        join_verification: bool,
    ) -> Result<(), sqlx::Error> {
        sqlx::query(
            "UPDATE group_info SET join_verification = $2, updated_at = NOW() WHERE conversation_id = $1"
        )
        .bind(conversation_id)
        .bind(join_verification)
        .execute(&self.db)
        .await?;
        Ok(())
    }

    /// 转让群主
    pub async fn transfer_owner(
        &self,
        conversation_id: Uuid,
        new_owner_id: i64,
    ) -> Result<(), sqlx::Error> {
        sqlx::query("UPDATE conversations SET owner_id = $2 WHERE id = $1")
            .bind(conversation_id)
            .bind(new_owner_id)
            .execute(&self.db)
            .await?;
        Ok(())
    }

    /// 解散群聊
    pub async fn disband(
        &self,
        conversation_id: Uuid,
    ) -> Result<(), sqlx::Error> {
        sqlx::query("UPDATE conversations SET status = 1 WHERE id = $1")
            .bind(conversation_id)
            .execute(&self.db)
            .await?;
        Ok(())
    }

    /// 更新群公告
    pub async fn update_announcement(
        &self,
        conversation_id: Uuid,
        announcement: &str,
        updated_by: i64,
    ) -> Result<(), sqlx::Error> {
        sqlx::query(
            "UPDATE group_info SET announcement = $2, announcement_updated_at = NOW(), announcement_updated_by = $3 WHERE conversation_id = $1"
        )
        .bind(conversation_id)
        .bind(announcement)
        .bind(updated_by)
        .execute(&self.db)
        .await?;
        Ok(())
    }

    /// 修改群信息（群名/头像，动态拼接）
    pub async fn update_group(
        &self,
        conversation_id: Uuid,
        name: Option<&str>,
        avatar: Option<&str>,
    ) -> Result<(), sqlx::Error> {
        let mut sets = Vec::new();
        let mut idx = 1u32;

        if name.is_some() {
            idx += 1;
            sets.push(format!("name = ${}", idx));
        }
        if avatar.is_some() {
            idx += 1;
            sets.push(format!("avatar = ${}", idx));
        }

        if sets.is_empty() {
            return Ok(());
        }

        let sql = format!(
            "UPDATE conversations SET {} WHERE id = $1",
            sets.join(", ")
        );

        let mut query = sqlx::query(&sql).bind(conversation_id);
        if let Some(n) = name {
            query = query.bind(n);
        }
        if let Some(a) = avatar {
            query = query.bind(a);
        }

        query.execute(&self.db).await?;
        Ok(())
    }
}
