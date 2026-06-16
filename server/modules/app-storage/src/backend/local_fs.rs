use std::path::PathBuf;
use tokio::fs;

use super::StorageBackend;

/// 本地文件系统存储后端
pub struct LocalFs {
    base_path: PathBuf,
}

impl LocalFs {
    pub fn new(base_path: PathBuf) -> Self {
        Self { base_path }
    }
}

impl StorageBackend for LocalFs {
    async fn put(&self, path: &str, data: &[u8]) -> Result<(), std::io::Error> {
        let full_path = self.base_path.join(path);
        if let Some(parent) = full_path.parent() {
            fs::create_dir_all(parent).await?;
        }
        fs::write(full_path, data).await
    }

    async fn get(&self, path: &str) -> Result<Vec<u8>, std::io::Error> {
        fs::read(self.base_path.join(path)).await
    }

    async fn delete(&self, path: &str) -> Result<(), std::io::Error> {
        fs::remove_file(self.base_path.join(path)).await
    }

    async fn exists(&self, path: &str) -> Result<bool, std::io::Error> {
        Ok(self.base_path.join(path).exists())
    }
}
