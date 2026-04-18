use sqlx::PgPool;
use uuid::Uuid;

use super::models::GroupConversation;

pub struct GroupRepository {
    db: PgPool,
}

impl GroupRepository {
    pub fn new(db: PgPool) -> Self {
        Self { db }
    }

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
}
