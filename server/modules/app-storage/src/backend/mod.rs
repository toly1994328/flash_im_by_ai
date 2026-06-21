pub mod local_fs;
pub mod oss;

pub use local_fs::LocalFs;
pub use oss::{OssBackend, OssConfig};

use std::future::Future;

/// 存储后端抽象 trait
///
/// 当前实现：LocalFs（本地文件系统）、OssBackend（阿里云 OSS，S3 兼容）
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
