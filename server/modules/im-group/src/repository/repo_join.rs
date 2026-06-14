use uuid::Uuid;

use crate::models::{GroupSearchResult, JoinRequestItem};
use super::GroupRepository;

impl GroupRepository {
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

    /// 根据 request_id 查询申请详情
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
}
