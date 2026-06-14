mod repo_create;
mod repo_join;
mod repo_membership;
mod repo_admin;

use sqlx::PgPool;

pub struct GroupRepository {
    pub(crate) db: PgPool,
}

impl GroupRepository {
    pub fn new(db: PgPool) -> Self {
        Self { db }
    }
}
