use sqlx::PgPool;
use uuid::Uuid;

use crate::model::{CategoryUsage, FileObject, UserStorageQuota};

/// 文件存储数据库访问层
pub struct StorageRepo;

impl StorageRepo {
    /// 按 SHA-1 hash 查找文件对象
    pub async fn find_by_hash(db: &PgPool, hash: &str) -> Result<Option<FileObject>, sqlx::Error> {
        sqlx::query_as::<_, FileObject>(
            "SELECT * FROM file_objects WHERE hash = $1"
        )
        .bind(hash)
        .fetch_optional(db)
        .await
    }

    /// 插入新文件对象
    pub async fn insert_file_object(
        db: &PgPool,
        hash: &str,
        storage_path: &str,
        size: i64,
        mime_type: &str,
        mime_category: &str,
        width: Option<i32>,
        height: Option<i32>,
        duration_ms: Option<i64>,
        thumb_path: Option<&str>,
        uploader_id: i64,
    ) -> Result<FileObject, sqlx::Error> {
        sqlx::query_as::<_, FileObject>(
            "INSERT INTO file_objects \
             (hash, storage_path, size, mime_type, mime_category, width, height, duration_ms, thumb_path, uploader_id) \
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) \
             RETURNING *"
        )
        .bind(hash)
        .bind(storage_path)
        .bind(size)
        .bind(mime_type)
        .bind(mime_category)
        .bind(width)
        .bind(height)
        .bind(duration_ms)
        .bind(thumb_path)
        .bind(uploader_id)
        .fetch_one(db)
        .await
    }

    /// 引用计数 +1
    pub async fn increment_ref_count(db: &PgPool, file_id: i64) -> Result<(), sqlx::Error> {
        sqlx::query("UPDATE file_objects SET ref_count = ref_count + 1 WHERE id = $1")
            .bind(file_id)
            .execute(db)
            .await?;
        Ok(())
    }

    /// 引用计数 -1（不低于 0）
    pub async fn decrement_ref_count(db: &PgPool, file_id: i64) -> Result<(), sqlx::Error> {
        sqlx::query("UPDATE file_objects SET ref_count = GREATEST(ref_count - 1, 0) WHERE id = $1")
            .bind(file_id)
            .execute(db)
            .await?;
        Ok(())
    }

    /// 获取用户配额
    pub async fn get_quota(db: &PgPool, user_id: i64) -> Result<Option<UserStorageQuota>, sqlx::Error> {
        sqlx::query_as::<_, UserStorageQuota>(
            "SELECT * FROM user_storage_quota WHERE user_id = $1"
        )
        .bind(user_id)
        .fetch_optional(db)
        .await
    }

    /// 创建用户配额记录（注册时）
    pub async fn create_quota(db: &PgPool, user_id: i64) -> Result<(), sqlx::Error> {
        sqlx::query(
            "INSERT INTO user_storage_quota (user_id) VALUES ($1) ON CONFLICT DO NOTHING"
        )
        .bind(user_id)
        .execute(db)
        .await?;
        Ok(())
    }

    /// 增减配额已用量
    pub async fn update_quota_used(db: &PgPool, user_id: i64, delta: i64) -> Result<(), sqlx::Error> {
        sqlx::query(
            "UPDATE user_storage_quota SET used_bytes = used_bytes + $2, updated_at = NOW() WHERE user_id = $1"
        )
        .bind(user_id)
        .bind(delta)
        .execute(db)
        .await?;
        Ok(())
    }

    /// 按类型聚合用户文件用量
    pub async fn get_usage_breakdown(db: &PgPool, user_id: i64) -> Result<Vec<CategoryUsage>, sqlx::Error> {
        sqlx::query_as::<_, CategoryUsage>(
            "SELECT mime_category, \
             COALESCE(SUM(size)::BIGINT, 0::BIGINT) as total_size, \
             COUNT(*)::BIGINT as file_count \
             FROM file_objects WHERE uploader_id = $1 \
             GROUP BY mime_category"
        )
        .bind(user_id)
        .fetch_all(db)
        .await
    }

    /// 插入文件引用记录
    pub async fn insert_reference(
        db: &PgPool,
        file_id: i64,
        message_id: Uuid,
        user_id: i64,
    ) -> Result<(), sqlx::Error> {
        sqlx::query(
            "INSERT INTO file_references (file_id, message_id, user_id) \
             VALUES ($1, $2, $3)"
        )
        .bind(file_id)
        .bind(message_id)
        .bind(user_id)
        .execute(db)
        .await?;
        Ok(())
    }

    /// 删除某条消息的所有文件引用，返回涉及的 file_id 列表
    pub async fn delete_references_by_message(
        db: &PgPool,
        message_id: Uuid,
    ) -> Result<Vec<i64>, sqlx::Error> {
        let rows: Vec<(i64,)> = sqlx::query_as(
            "DELETE FROM file_references WHERE message_id = $1 RETURNING file_id"
        )
        .bind(message_id)
        .fetch_all(db)
        .await?;
        Ok(rows.into_iter().map(|(id,)| id).collect())
    }
}
