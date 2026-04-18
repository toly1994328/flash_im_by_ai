use axum::http::StatusCode;
use sqlx::PgPool;

use super::models::GroupConversation;
use super::repository::GroupRepository;

pub struct GroupService {
    repo: GroupRepository,
    db: PgPool,
}

impl GroupService {
    pub fn new(db: PgPool) -> Self {
        let repo = GroupRepository::new(db.clone());
        Self { repo, db }
    }

    pub fn db(&self) -> &PgPool {
        &self.db
    }

    /// 创建群聊
    pub async fn create_group(
        &self,
        owner_id: i64,
        name: &str,
        member_ids: &[i64],
    ) -> Result<GroupConversation, StatusCode> {
        let name = name.trim();
        if name.is_empty() {
            return Err(StatusCode::BAD_REQUEST);
        }

        // 去重，排除群主
        let unique_members: Vec<i64> = member_ids.iter()
            .copied()
            .filter(|&id| id != owner_id)
            .collect::<std::collections::HashSet<_>>()
            .into_iter()
            .collect();

        // 加上群主至少 3 人
        if unique_members.len() < 2 {
            return Err(StatusCode::BAD_REQUEST);
        }
        if unique_members.len() + 1 > 200 {
            return Err(StatusCode::BAD_REQUEST);
        }

        self.repo.create_group(name, owner_id, &unique_members)
            .await
            .map_err(|e| {
                println!("❌ [group] create_group failed: {}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })
    }
}
