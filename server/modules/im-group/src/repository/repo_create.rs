use uuid::Uuid;

use crate::models::{GroupConversation, GroupInfoRow, GroupMember};
use super::GroupRepository;

impl GroupRepository {
    /// 创建群聊会话（事务）
    pub async fn create_group(
        &self,
        name: &str,
        owner_id: i64,
        member_ids: &[i64],
    ) -> Result<GroupConversation, sqlx::Error> {
        let mut tx = self.db.begin().await?;

        let conv = sqlx::query_as::<_, GroupConversation>(
            "INSERT INTO conversations (type, name, owner_id) VALUES (1, $1, $2)
             RETURNING id, type, name, avatar, owner_id, created_at"
        )
        .bind(name)
        .bind(owner_id)
        .fetch_one(&mut *tx)
        .await?;

        // 插入群主
        sqlx::query(
            "INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2)
             ON CONFLICT (conversation_id, user_id) DO UPDATE SET is_deleted = FALSE, joined_at = NOW()"
        )
        .bind(conv.id)
        .bind(owner_id)
        .execute(&mut *tx)
        .await?;

        // 插入其他成员
        for &uid in member_ids {
            if uid != owner_id {
                sqlx::query(
                    "INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2)
                     ON CONFLICT (conversation_id, user_id) DO UPDATE SET is_deleted = FALSE, joined_at = NOW()"
                )
                .bind(conv.id)
                .bind(uid)
                .execute(&mut *tx)
                .await?;
            }
        }

        // 初始化 group_info
        sqlx::query(
            "INSERT INTO group_info (conversation_id) VALUES ($1)
             ON CONFLICT (conversation_id) DO NOTHING"
        )
        .bind(conv.id)
        .execute(&mut *tx)
        .await?;

        tx.commit().await?;

        // 生成宫格头像（事务外）
        let avatar = self.build_grid_avatar(conv.id).await?;
        sqlx::query("UPDATE conversations SET avatar = $2 WHERE id = $1")
            .bind(conv.id)
            .bind(&avatar)
            .execute(&self.db)
            .await?;

        // 重新查询返回完整数据
        sqlx::query_as::<_, GroupConversation>(
            "SELECT id, type, name, avatar, owner_id, created_at
             FROM conversations WHERE id = $1"
        )
        .bind(conv.id)
        .fetch_one(&self.db)
        .await
    }

    /// 生成宫格头像字符串（取前 9 个成员头像）
    pub async fn build_grid_avatar(
        &self,
        conversation_id: Uuid,
    ) -> Result<String, sqlx::Error> {
        let rows: Vec<(Option<String>,)> = sqlx::query_as(
            "SELECT up.avatar
             FROM conversation_members cm
             LEFT JOIN user_profiles up ON cm.user_id = up.account_id
             WHERE cm.conversation_id = $1 AND cm.is_deleted = FALSE
             ORDER BY cm.joined_at
             LIMIT 9"
        )
        .bind(conversation_id)
        .fetch_all(&self.db)
        .await?;

        let avatars: Vec<String> = rows
            .into_iter()
            .map(|(avatar,)| avatar.unwrap_or_default())
            .collect();

        Ok(format!("grid:{}", avatars.join(",")))
    }

    /// 查询群成员列表（带用户信息）
    pub async fn get_group_members(
        &self,
        conversation_id: Uuid,
    ) -> Result<Vec<GroupMember>, sqlx::Error> {
        sqlx::query_as::<_, GroupMember>(
            r#"SELECT cm.user_id,
                    COALESCE(up.nickname, '未知用户') AS nickname,
                    up.avatar,
                    cm.last_read_seq
                FROM conversation_members cm
                LEFT JOIN user_profiles up ON cm.user_id = up.account_id
                JOIN conversations c ON c.id = cm.conversation_id
                WHERE cm.conversation_id = $1 AND cm.is_deleted = false
                ORDER BY CASE WHEN cm.user_id = c.owner_id THEN 0 ELSE 1 END, cm.joined_at"#
        )
        .bind(conversation_id)
        .fetch_all(&self.db)
        .await
    }

    /// 查询群基本信息（用于群详情）
    pub async fn get_group_info(
        &self,
        conversation_id: Uuid,
    ) -> Result<Option<GroupInfoRow>, sqlx::Error> {
        sqlx::query_as::<_, GroupInfoRow>(
            r#"SELECT c.name, c.avatar, c.owner_id, COALESCE(gi.group_no, 0) AS group_no,
                COALESCE(gi.join_verification, false) AS join_verification,
                COALESCE(c.status, 0::SMALLINT) AS status, gi.announcement, gi.announcement_updated_at
                FROM conversations c
                LEFT JOIN group_info gi ON gi.conversation_id = c.id
                WHERE c.id = $1 AND c.type = 1"#
        )
        .bind(conversation_id)
        .fetch_optional(&self.db)
        .await
    }

    /// 查询群主 ID
    pub async fn get_group_owner(
        &self,
        conversation_id: Uuid,
    ) -> Result<Option<i64>, sqlx::Error> {
        let row: Option<(Option<i64>,)> = sqlx::query_as(
            "SELECT owner_id FROM conversations WHERE id = $1 AND type = 1"
        )
        .bind(conversation_id)
        .fetch_optional(&self.db)
        .await?;
        Ok(row.and_then(|(owner,)| owner))
    }

    /// 查询群成员数量
    pub async fn get_member_count(
        &self,
        conversation_id: Uuid,
    ) -> Result<i64, sqlx::Error> {
        let (count,): (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM conversation_members WHERE conversation_id = $1 AND is_deleted = false"
        )
        .bind(conversation_id)
        .fetch_one(&self.db)
        .await?;
        Ok(count)
    }

    /// 查询群聊状态（0=正常, 1=已解散）
    pub async fn get_conversation_status(
        &self,
        conversation_id: Uuid,
    ) -> Result<i16, sqlx::Error> {
        let (status,): (i16,) = sqlx::query_as(
            "SELECT COALESCE(status, 0::SMALLINT) FROM conversations WHERE id = $1"
        )
        .bind(conversation_id)
        .fetch_one(&self.db)
        .await?;
        Ok(status)
    }

    /// 查询群成员 ID 列表（活跃成员）
    pub async fn get_member_ids(
        &self,
        conversation_id: Uuid,
    ) -> Result<Vec<i64>, sqlx::Error> {
        let rows: Vec<(i64,)> = sqlx::query_as(
            "SELECT user_id FROM conversation_members WHERE conversation_id = $1 AND is_deleted = false"
        )
        .bind(conversation_id)
        .fetch_all(&self.db)
        .await?;
        Ok(rows.into_iter().map(|(id,)| id).collect())
    }
}
