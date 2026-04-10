use sqlx::PgPool;
use uuid::Uuid;

use crate::models::{
    FriendRelation, FriendRequest, FriendRequestWithProfile, FriendWithProfile,
};

pub struct FriendRepository {
    pool: PgPool,
}

impl FriendRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub fn pool(&self) -> &PgPool {
        &self.pool
    }

    /// 创建好友申请
    pub async fn create_request(
        &self,
        from_user_id: i64,
        to_user_id: i64,
        message: Option<&str>,
    ) -> Result<FriendRequest, sqlx::Error> {
        sqlx::query_as(
            "INSERT INTO friend_requests (from_user_id, to_user_id, message) \
             VALUES ($1, $2, $3) \
             ON CONFLICT (from_user_id, to_user_id) \
             DO UPDATE SET message = $3, status = 0, updated_at = NOW() \
             RETURNING *",
        )
        .bind(from_user_id)
        .bind(to_user_id)
        .bind(message)
        .fetch_one(&self.pool)
        .await
    }

    /// 按 ID 查找申请
    pub async fn find_request_by_id(&self, id: Uuid) -> Result<Option<FriendRequest>, sqlx::Error> {
        sqlx::query_as("SELECT * FROM friend_requests WHERE id = $1")
            .bind(id)
            .fetch_optional(&self.pool)
            .await
    }

    /// 查找两人之间的待处理申请
    pub async fn find_pending_request(
        &self,
        from_user_id: i64,
        to_user_id: i64,
    ) -> Result<Option<FriendRequest>, sqlx::Error> {
        sqlx::query_as(
            "SELECT * FROM friend_requests \
             WHERE from_user_id = $1 AND to_user_id = $2 AND status = 0",
        )
        .bind(from_user_id)
        .bind(to_user_id)
        .fetch_optional(&self.pool)
        .await
    }

    /// 更新申请状态
    pub async fn update_request_status(
        &self,
        id: Uuid,
        status: i16,
    ) -> Result<FriendRequest, sqlx::Error> {
        sqlx::query_as(
            "UPDATE friend_requests SET status = $2, updated_at = NOW() \
             WHERE id = $1 RETURNING *",
        )
        .bind(id)
        .bind(status)
        .fetch_one(&self.pool)
        .await
    }

    /// 获取收到的申请（带发送者信息）
    pub async fn get_received_requests(
        &self,
        user_id: i64,
        limit: i32,
        offset: i32,
    ) -> Result<Vec<FriendRequestWithProfile>, sqlx::Error> {
        let rows: Vec<(Uuid, i64, i64, Option<String>, i16,
            chrono::DateTime<chrono::Utc>, chrono::DateTime<chrono::Utc>,
            String, Option<String>)> = sqlx::query_as(
            "SELECT r.id, r.from_user_id, r.to_user_id, r.message, r.status, \
                    r.created_at, r.updated_at, \
                    COALESCE(p.nickname, '?'), p.avatar \
             FROM friend_requests r \
             LEFT JOIN user_profiles p ON p.account_id = r.from_user_id \
             WHERE r.to_user_id = $1 AND r.status = 0 \
             ORDER BY r.created_at DESC \
             LIMIT $2 OFFSET $3",
        )
        .bind(user_id)
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(|(id, from_user_id, to_user_id, message, status, created_at, updated_at, nickname, avatar)| {
            FriendRequestWithProfile {
                request: FriendRequest { id, from_user_id, to_user_id, message, status, created_at, updated_at },
                nickname,
                avatar,
            }
        }).collect())
    }

    /// 获取发送的申请（带接收者信息）
    pub async fn get_sent_requests(
        &self,
        user_id: i64,
        limit: i32,
        offset: i32,
    ) -> Result<Vec<FriendRequestWithProfile>, sqlx::Error> {
        let rows: Vec<(Uuid, i64, i64, Option<String>, i16,
            chrono::DateTime<chrono::Utc>, chrono::DateTime<chrono::Utc>,
            String, Option<String>)> = sqlx::query_as(
            "SELECT r.id, r.from_user_id, r.to_user_id, r.message, r.status, \
                    r.created_at, r.updated_at, \
                    COALESCE(p.nickname, '?'), p.avatar \
             FROM friend_requests r \
             LEFT JOIN user_profiles p ON p.account_id = r.to_user_id \
             WHERE r.from_user_id = $1 \
             ORDER BY r.created_at DESC \
             LIMIT $2 OFFSET $3",
        )
        .bind(user_id)
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(|(id, from_user_id, to_user_id, message, status, created_at, updated_at, nickname, avatar)| {
            FriendRequestWithProfile {
                request: FriendRequest { id, from_user_id, to_user_id, message, status, created_at, updated_at },
                nickname,
                avatar,
            }
        }).collect())
    }

    /// 创建双向好友关系（事务）
    pub async fn create_relation(
        &self,
        user_id: i64,
        friend_id: i64,
    ) -> Result<FriendRelation, sqlx::Error> {
        let mut tx = self.pool.begin().await?;

        sqlx::query(
            "INSERT INTO friend_relations (user_id, friend_id) VALUES ($1, $2) \
             ON CONFLICT DO NOTHING",
        )
        .bind(user_id)
        .bind(friend_id)
        .execute(&mut *tx)
        .await?;

        sqlx::query(
            "INSERT INTO friend_relations (user_id, friend_id) VALUES ($1, $2) \
             ON CONFLICT DO NOTHING",
        )
        .bind(friend_id)
        .bind(user_id)
        .execute(&mut *tx)
        .await?;

        tx.commit().await?;

        Ok(FriendRelation {
            user_id,
            friend_id,
            created_at: chrono::Utc::now(),
        })
    }

    /// 删除申请记录（只有申请的发送方或接收方可以删除）
    pub async fn delete_request(&self, id: Uuid, user_id: i64) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            "DELETE FROM friend_requests WHERE id = $1 AND (from_user_id = $2 OR to_user_id = $2)",
        )
        .bind(id)
        .bind(user_id)
        .execute(&self.pool)
        .await?;
        Ok(result.rows_affected() > 0)
    }

    /// 删除好友关系
    pub async fn delete_relation(
        &self,
        user_id: i64,
        friend_id: i64,
    ) -> Result<(), sqlx::Error> {
        let mut tx = self.pool.begin().await?;

        sqlx::query("DELETE FROM friend_relations WHERE user_id = $1 AND friend_id = $2")
            .bind(user_id)
            .bind(friend_id)
            .execute(&mut *tx)
            .await?;

        sqlx::query("DELETE FROM friend_relations WHERE user_id = $1 AND friend_id = $2")
            .bind(friend_id)
            .bind(user_id)
            .execute(&mut *tx)
            .await?;

        tx.commit().await?;
        Ok(())
    }

    /// 获取好友列表（带用户信息）
    pub async fn get_friends(
        &self,
        user_id: i64,
        limit: i32,
        offset: i32,
    ) -> Result<Vec<FriendWithProfile>, sqlx::Error> {
        sqlx::query_as(
            "SELECT fr.friend_id, \
                    COALESCE(p.nickname, '?') AS nickname, \
                    p.avatar, p.bio, fr.created_at \
             FROM friend_relations fr \
             LEFT JOIN user_profiles p ON p.account_id = fr.friend_id \
             WHERE fr.user_id = $1 \
             ORDER BY p.nickname \
             LIMIT $2 OFFSET $3",
        )
        .bind(user_id)
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.pool)
        .await
    }

    /// 检查是否是好友
    pub async fn is_friend(&self, user_id: i64, friend_id: i64) -> Result<bool, sqlx::Error> {
        let row: Option<(i32,)> = sqlx::query_as(
            "SELECT 1 FROM friend_relations WHERE user_id = $1 AND friend_id = $2",
        )
        .bind(user_id)
        .bind(friend_id)
        .fetch_optional(&self.pool)
        .await?;
        Ok(row.is_some())
    }

    /// 检查用户是否存在
    pub async fn user_exists(&self, user_id: i64) -> Result<bool, sqlx::Error> {
        let row: Option<(i64,)> =
            sqlx::query_as("SELECT id FROM accounts WHERE id = $1 AND status = 0")
                .bind(user_id)
                .fetch_optional(&self.pool)
                .await?;
        Ok(row.is_some())
    }

    /// 获取用户昵称和头像
    pub async fn get_user_profile(
        &self,
        user_id: i64,
    ) -> Result<Option<(String, Option<String>)>, sqlx::Error> {
        sqlx::query_as(
            "SELECT nickname, avatar FROM user_profiles WHERE account_id = $1",
        )
        .bind(user_id)
        .fetch_optional(&self.pool)
        .await
    }
}
