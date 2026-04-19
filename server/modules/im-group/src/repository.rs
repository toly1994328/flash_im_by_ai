use sqlx::PgPool;
use uuid::Uuid;

use super::models::{GroupConversation, GroupSearchResult, JoinRequestItem, GroupMember};

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

    // ─── v0.0.2：搜索加群与入群审批 ───

    /// 搜索群聊（按群名模糊搜索或群号精确匹配）
    pub async fn search_groups(
        &self,
        user_id: i64,
        keyword: &str,
        is_numeric: bool,
    ) -> Result<Vec<GroupSearchResult>, sqlx::Error> {
        if is_numeric {
            let group_no: i64 = keyword.parse().unwrap_or(0);
            sqlx::query_as::<_, GroupSearchResult>(
                r#"SELECT c.id, c.name, c.avatar, c.owner_id, gi.group_no,
                    (SELECT COUNT(*) FROM conversation_members WHERE conversation_id = c.id AND is_deleted = false) AS member_count,
                    EXISTS(SELECT 1 FROM conversation_members WHERE conversation_id = c.id AND user_id = $1 AND is_deleted = false) AS is_member,
                    COALESCE(gi.join_verification, false) AS join_verification,
                    EXISTS(SELECT 1 FROM group_join_requests WHERE conversation_id = c.id AND user_id = $1 AND status = 0) AS has_pending_request
                FROM conversations c
                LEFT JOIN group_info gi ON gi.conversation_id = c.id
                WHERE c.type = 1 AND gi.group_no = $2
                LIMIT 20"#
            )
            .bind(user_id)
            .bind(group_no)
            .fetch_all(&self.db)
            .await
        } else {
            // 转义 ILIKE 通配符
            let escaped = keyword.replace('%', "\\%").replace('_', "\\_");
            let pattern = format!("%{}%", escaped);
            sqlx::query_as::<_, GroupSearchResult>(
                r#"SELECT c.id, c.name, c.avatar, c.owner_id, gi.group_no,
                    (SELECT COUNT(*) FROM conversation_members WHERE conversation_id = c.id AND is_deleted = false) AS member_count,
                    EXISTS(SELECT 1 FROM conversation_members WHERE conversation_id = c.id AND user_id = $1 AND is_deleted = false) AS is_member,
                    COALESCE(gi.join_verification, false) AS join_verification,
                    EXISTS(SELECT 1 FROM group_join_requests WHERE conversation_id = c.id AND user_id = $1 AND status = 0) AS has_pending_request
                FROM conversations c
                LEFT JOIN group_info gi ON gi.conversation_id = c.id
                WHERE c.type = 1 AND c.name ILIKE $2
                ORDER BY member_count DESC
                LIMIT 20"#
            )
            .bind(user_id)
            .bind(&pattern)
            .fetch_all(&self.db)
            .await
        }
    }

    /// 直接加入群聊（无需验证）
    pub async fn join_group_direct(
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

        // 刷新宫格头像
        let avatar = self.build_grid_avatar(conversation_id).await?;
        sqlx::query("UPDATE conversations SET avatar = $2 WHERE id = $1")
            .bind(conversation_id)
            .bind(&avatar)
            .execute(&self.db)
            .await?;

        Ok(())
    }

    /// 创建入群申请
    pub async fn create_join_request(
        &self,
        conversation_id: Uuid,
        user_id: i64,
        message: Option<&str>,
    ) -> Result<Uuid, sqlx::Error> {
        let (id,): (Uuid,) = sqlx::query_as(
            "INSERT INTO group_join_requests (conversation_id, user_id, message)
             VALUES ($1, $2, $3) RETURNING id"
        )
        .bind(conversation_id)
        .bind(user_id)
        .bind(message)
        .fetch_one(&self.db)
        .await?;
        Ok(id)
    }

    /// 查询用户对某群是否有待处理申请
    pub async fn find_pending_request(
        &self,
        conversation_id: Uuid,
        user_id: i64,
    ) -> Result<Option<Uuid>, sqlx::Error> {
        let row: Option<(Uuid,)> = sqlx::query_as(
            "SELECT id FROM group_join_requests WHERE conversation_id = $1 AND user_id = $2 AND status = 0"
        )
        .bind(conversation_id)
        .bind(user_id)
        .fetch_optional(&self.db)
        .await?;
        Ok(row.map(|(id,)| id))
    }

    /// 根据 request_id 查询申请详情，返回 (conversation_id, user_id, status)
    pub async fn get_join_request(
        &self,
        request_id: Uuid,
    ) -> Result<Option<(Uuid, i64, i16)>, sqlx::Error> {
        sqlx::query_as(
            "SELECT conversation_id, user_id, status FROM group_join_requests WHERE id = $1"
        )
        .bind(request_id)
        .fetch_optional(&self.db)
        .await
    }

    /// 更新入群申请状态
    pub async fn update_join_request_status(
        &self,
        request_id: Uuid,
        status: i16,
    ) -> Result<(), sqlx::Error> {
        sqlx::query(
            "UPDATE group_join_requests SET status = $2, updated_at = NOW() WHERE id = $1"
        )
        .bind(request_id)
        .bind(status)
        .execute(&self.db)
        .await?;
        Ok(())
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

    /// 查询群的入群验证开关
    pub async fn get_join_verification(
        &self,
        conversation_id: Uuid,
    ) -> Result<bool, sqlx::Error> {
        let row: Option<(bool,)> = sqlx::query_as(
            "SELECT COALESCE(join_verification, false) FROM group_info WHERE conversation_id = $1"
        )
        .bind(conversation_id)
        .fetch_optional(&self.db)
        .await?;
        Ok(row.map(|(v,)| v).unwrap_or(false))
    }

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

    /// 查询当前用户作为群主的所有入群申请
    pub async fn list_join_requests(
        &self,
        owner_id: i64,
    ) -> Result<Vec<JoinRequestItem>, sqlx::Error> {
        sqlx::query_as::<_, JoinRequestItem>(
            r#"SELECT gjr.id, gjr.conversation_id,
                    c.name AS group_name, c.avatar AS group_avatar,
                    gjr.user_id,
                    COALESCE(up.nickname, '未知用户') AS nickname,
                    up.avatar,
                    gjr.message, gjr.status, gjr.created_at
                FROM group_join_requests gjr
                INNER JOIN conversations c ON gjr.conversation_id = c.id
                LEFT JOIN user_profiles up ON gjr.user_id = up.account_id
                WHERE c.owner_id = $1 AND c.type = 1
                ORDER BY gjr.created_at DESC"#
        )
        .bind(owner_id)
        .fetch_all(&self.db)
        .await
    }

    // ─── 群详情与群设置 ───

    /// 查询群成员列表（带用户信息）
    pub async fn get_group_members(
        &self,
        conversation_id: Uuid,
    ) -> Result<Vec<GroupMember>, sqlx::Error> {
        sqlx::query_as::<_, GroupMember>(
            r#"SELECT cm.user_id,
                    COALESCE(up.nickname, '未知用户') AS nickname,
                    up.avatar
                FROM conversation_members cm
                LEFT JOIN user_profiles up ON cm.user_id = up.account_id
                WHERE cm.conversation_id = $1 AND cm.is_deleted = false
                ORDER BY cm.joined_at"#
        )
        .bind(conversation_id)
        .fetch_all(&self.db)
        .await
    }

    /// 查询群基本信息（用于群详情）
    pub async fn get_group_info(
        &self,
        conversation_id: Uuid,
    ) -> Result<Option<(Option<String>, Option<String>, Option<i64>, i64, bool)>, sqlx::Error> {
        // 返回 (name, avatar, owner_id, group_no, join_verification)
        sqlx::query_as(
            r#"SELECT c.name, c.avatar, c.owner_id, COALESCE(gi.group_no, 0), COALESCE(gi.join_verification, false)
                FROM conversations c
                LEFT JOIN group_info gi ON gi.conversation_id = c.id
                WHERE c.id = $1 AND c.type = 1"#
        )
        .bind(conversation_id)
        .fetch_optional(&self.db)
        .await
    }

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
}
