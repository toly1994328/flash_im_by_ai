use sqlx::PgPool;
use uuid::Uuid;

use super::models::{Conversation, ConversationListItem, GroupSearchResult, GroupJoinRequest, MyJoinRequestItem};

pub struct ConversationRepository {
    db: PgPool,
}

impl ConversationRepository {
    pub fn new(db: PgPool) -> Self {
        Self { db }
    }

    /// 查询两人之间是否已有私聊会话
    pub async fn find_private(
        &self,
        user_a: i64,
        user_b: i64,
    ) -> Result<Option<Conversation>, sqlx::Error> {
        sqlx::query_as::<_, Conversation>(
            "SELECT c.id, c.type, c.name, c.avatar, c.owner_id,
                    c.last_message_at, c.last_message_preview,
                    c.created_at, c.updated_at
             FROM conversations c
             JOIN conversation_members m1 ON m1.conversation_id = c.id AND m1.user_id = $1
             JOIN conversation_members m2 ON m2.conversation_id = c.id AND m2.user_id = $2
             WHERE c.type = 0"
        )
        .bind(user_a)
        .bind(user_b)
        .fetch_optional(&self.db)
        .await
    }

    /// 创建私聊会话（事务）
    pub async fn create_private(
        &self,
        user_a: i64,
        user_b: i64,
    ) -> Result<Conversation, sqlx::Error> {
        let mut tx = self.db.begin().await?;

        let conv = sqlx::query_as::<_, Conversation>(
            "INSERT INTO conversations (type) VALUES (0)
             RETURNING id, type, name, avatar, owner_id,
                       last_message_at, last_message_preview,
                       created_at, updated_at"
        )
        .fetch_one(&mut *tx)
        .await?;

        sqlx::query(
            "INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2)"
        )
        .bind(conv.id)
        .bind(user_a)
        .execute(&mut *tx)
        .await?;

        sqlx::query(
            "INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2)"
        )
        .bind(conv.id)
        .bind(user_b)
        .execute(&mut *tx)
        .await?;

        tx.commit().await?;
        Ok(conv)
    }

    /// 查询用户的会话列表（分页）
    pub async fn list_by_user(
        &self,
        user_id: i64,
        limit: i32,
        offset: i32,
    ) -> Result<Vec<ConversationListItem>, sqlx::Error> {
        sqlx::query_as::<_, ConversationListItem>(
            "SELECT c.id, c.type AS conv_type, c.name, c.avatar, c.owner_id,
                    c.last_message_at, c.last_message_preview,
                    c.created_at, c.updated_at,
                    cm.unread_count, cm.last_read_seq, cm.is_pinned, cm.is_muted,
                    peer.user_id AS peer_user_id
             FROM conversations c
             JOIN conversation_members cm ON cm.conversation_id = c.id AND cm.user_id = $1
             LEFT JOIN conversation_members peer ON peer.conversation_id = c.id
                       AND peer.user_id != $1 AND c.type = 0
             WHERE cm.is_deleted = false
             ORDER BY c.last_message_at DESC NULLS LAST, c.created_at DESC
             LIMIT $2 OFFSET $3"
        )
        .bind(user_id)
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.db)
        .await
    }

    /// 软删除会话
    pub async fn delete_for_user(
        &self,
        conversation_id: Uuid,
        user_id: i64,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            "UPDATE conversation_members SET is_deleted = true
             WHERE conversation_id = $1 AND user_id = $2"
        )
        .bind(conversation_id)
        .bind(user_id)
        .execute(&self.db)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    // ==================== 群聊 ====================

    /// 创建群聊会话（事务）
    pub async fn create_group(
        &self,
        name: &str,
        owner_id: i64,
        member_ids: &[i64],
    ) -> Result<Conversation, sqlx::Error> {
        let mut tx = self.db.begin().await?;

        let conv = sqlx::query_as::<_, Conversation>(
            "INSERT INTO conversations (type, name, owner_id) VALUES (1, $1, $2)
             RETURNING id, type, name, avatar, owner_id,
                       last_message_at, last_message_preview,
                       created_at, updated_at"
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
        sqlx::query_as::<_, Conversation>(
            "SELECT id, type, name, avatar, owner_id,
                    last_message_at, last_message_preview,
                    created_at, updated_at
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

    /// 添加单个成员（入群时使用）
    pub async fn add_member(
        &self,
        conversation_id: Uuid,
        user_id: i64,
    ) -> Result<(), sqlx::Error> {
        sqlx::query(
            "INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2)
             ON CONFLICT (conversation_id, user_id) DO UPDATE SET is_deleted = FALSE, joined_at = NOW()"
        )
        .bind(conversation_id)
        .bind(user_id)
        .execute(&self.db)
        .await?;
        Ok(())
    }

    /// 根据 ID 查询会话
    pub async fn find_by_id(
        &self,
        id: Uuid,
    ) -> Result<Option<Conversation>, sqlx::Error> {
        sqlx::query_as::<_, Conversation>(
            "SELECT id, type, name, avatar, owner_id,
                    last_message_at, last_message_preview,
                    created_at, updated_at
             FROM conversations WHERE id = $1"
        )
        .bind(id)
        .fetch_optional(&self.db)
        .await
    }

    /// 检查用户是否是会话成员
    pub async fn is_member(
        &self,
        conversation_id: Uuid,
        user_id: i64,
    ) -> Result<bool, sqlx::Error> {
        let row: Option<(i32,)> = sqlx::query_as(
            "SELECT 1 FROM conversation_members
             WHERE conversation_id = $1 AND user_id = $2 AND is_deleted = FALSE"
        )
        .bind(conversation_id)
        .bind(user_id)
        .fetch_optional(&self.db)
        .await?;
        Ok(row.is_some())
    }

    // ==================== 群搜索 ====================

    /// 搜索群聊
    pub async fn search_groups(
        &self,
        keyword: &str,
        user_id: i64,
        limit: i32,
    ) -> Result<Vec<GroupSearchResult>, sqlx::Error> {
        let pattern = format!("%{}%", keyword);
        sqlx::query_as::<_, GroupSearchResult>(
            "SELECT
                c.id, c.name, c.avatar,
                (SELECT COUNT(*) FROM conversation_members cm2
                 WHERE cm2.conversation_id = c.id AND cm2.is_deleted = FALSE) as member_count,
                EXISTS(
                    SELECT 1 FROM conversation_members cm3
                    WHERE cm3.conversation_id = c.id AND cm3.user_id = $2 AND cm3.is_deleted = FALSE
                ) as is_member,
                COALESCE(gi.join_verification, false) as join_verification
             FROM conversations c
             LEFT JOIN group_info gi ON c.id = gi.conversation_id
             WHERE c.type = 1 AND c.name ILIKE $1
             ORDER BY c.created_at DESC
             LIMIT $3"
        )
        .bind(&pattern)
        .bind(user_id)
        .bind(limit)
        .fetch_all(&self.db)
        .await
    }

    // ==================== 入群申请 ====================

    /// 查询入群验证开关
    pub async fn get_group_join_verification(
        &self,
        conversation_id: Uuid,
    ) -> Result<bool, sqlx::Error> {
        let row: Option<(bool,)> = sqlx::query_as(
            "SELECT join_verification FROM group_info WHERE conversation_id = $1"
        )
        .bind(conversation_id)
        .fetch_optional(&self.db)
        .await?;
        Ok(row.map(|(v,)| v).unwrap_or(false))
    }

    /// 创建入群申请
    pub async fn create_join_request(
        &self,
        user_id: i64,
        conversation_id: Uuid,
        message: Option<&str>,
    ) -> Result<GroupJoinRequest, sqlx::Error> {
        sqlx::query_as::<_, GroupJoinRequest>(
            "INSERT INTO group_join_requests (user_id, conversation_id, message)
             VALUES ($1, $2, $3)
             RETURNING *"
        )
        .bind(user_id)
        .bind(conversation_id)
        .bind(message)
        .fetch_one(&self.db)
        .await
    }

    /// 查询用户对某群的待处理申请
    pub async fn find_pending_join_request(
        &self,
        user_id: i64,
        conversation_id: Uuid,
    ) -> Result<Option<GroupJoinRequest>, sqlx::Error> {
        sqlx::query_as::<_, GroupJoinRequest>(
            "SELECT * FROM group_join_requests
             WHERE user_id = $1 AND conversation_id = $2 AND status = 0"
        )
        .bind(user_id)
        .bind(conversation_id)
        .fetch_optional(&self.db)
        .await
    }

    /// 根据 ID 查询入群申请
    pub async fn find_join_request_by_id(
        &self,
        id: Uuid,
    ) -> Result<Option<GroupJoinRequest>, sqlx::Error> {
        sqlx::query_as::<_, GroupJoinRequest>(
            "SELECT * FROM group_join_requests WHERE id = $1"
        )
        .bind(id)
        .fetch_optional(&self.db)
        .await
    }

    /// 更新入群申请状态
    pub async fn update_join_request_status(
        &self,
        id: Uuid,
        status: i16,
        handled_by: i64,
    ) -> Result<GroupJoinRequest, sqlx::Error> {
        sqlx::query_as::<_, GroupJoinRequest>(
            "UPDATE group_join_requests
             SET status = $2, handled_by = $3, updated_at = NOW()
             WHERE id = $1
             RETURNING *"
        )
        .bind(id)
        .bind(status)
        .bind(handled_by)
        .fetch_one(&self.db)
        .await
    }

    /// 获取当前用户作为群主的所有待处理入群申请
    pub async fn get_my_pending_join_requests(
        &self,
        user_id: i64,
        limit: i32,
        offset: i32,
    ) -> Result<Vec<MyJoinRequestItem>, sqlx::Error> {
        let rows: Vec<(
            Uuid, i64, Uuid, Option<String>, i16, Option<i64>,
            chrono::DateTime<chrono::Utc>, chrono::DateTime<chrono::Utc>,
            String, Option<String>, Option<String>,
        )> = sqlx::query_as(
            "SELECT
                gjr.id, gjr.user_id, gjr.conversation_id, gjr.message, gjr.status,
                gjr.handled_by, gjr.created_at, gjr.updated_at,
                COALESCE(up.nickname, '未知用户') as nickname, up.avatar,
                c.name as group_name
             FROM group_join_requests gjr
             LEFT JOIN user_profiles up ON gjr.user_id = up.account_id
             INNER JOIN conversations c ON gjr.conversation_id = c.id
             WHERE c.owner_id = $1 AND gjr.status = 0
             ORDER BY gjr.created_at DESC
             LIMIT $2 OFFSET $3"
        )
        .bind(user_id)
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.db)
        .await?;

        Ok(rows.into_iter().map(|(id, uid, conv_id, message, status, handled_by, created_at, updated_at, nickname, avatar, group_name)| {
            MyJoinRequestItem {
                request: GroupJoinRequest {
                    id,
                    user_id: uid,
                    conversation_id: conv_id,
                    message,
                    status,
                    handled_by,
                    created_at,
                    updated_at,
                },
                nickname,
                avatar,
                group_name,
            }
        }).collect())
    }
}
