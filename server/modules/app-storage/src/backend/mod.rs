pub mod local_fs;

pub use local_fs::LocalFs;

use std::future::Future;

/// 存储后端抽象 trait
///
/// 当前实现：LocalFs（本地文件系统）
/// 未来扩展：S3Backend（兼容 MinIO / 阿里云 OSS）
pub trait StorageBackend: Send + Sync + 'static {
    /// 写入文件到指定相对路径
    fn put(&self, path: &str, data: &[u8]) -> impl Future<Output = Result<(), std::io::Error>> + Send;

    /// 读取文件内容
    fn get(&self, path: &str) -> impl Future<Output = Result<Vec<u8>, std::io::Error>> + Send;

    /// 删除文件
    fn delete(&self, path: &str) -> impl Future<Output = Result<(), std::io::Error>> + Send;

    /// 判断文件是否存在
    fn exists(&self, path: &str) -> impl Future<Output = Result<bool, std::io::Error>> + Send;
}
