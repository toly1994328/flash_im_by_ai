use aws_sdk_s3::Client;
use aws_sdk_s3::config::{Credentials, Region};
use aws_sdk_s3::primitives::ByteStream;

use super::StorageBackend;

/// 阿里云 OSS 存储后端（S3 兼容协议）
pub struct OssBackend {
    client: Client,
    bucket: String,
    /// 公网访问 URL 前缀，如 https://flash-im-storage.oss-cn-beijing.aliyuncs.com
    pub url_prefix: String,
}

/// OSS 配置
pub struct OssConfig {
    pub endpoint: String,
    pub bucket: String,
    pub access_key_id: String,
    pub access_key_secret: String,
    pub region: String,
}

impl OssConfig {
    /// 从环境变量读取 OSS 配置，返回 None 表示未配置
    pub fn from_env() -> Option<Self> {
        let endpoint = std::env::var("OSS_ENDPOINT").ok()?;
        let bucket = std::env::var("OSS_BUCKET").ok()?;
        let access_key_id = std::env::var("OSS_ACCESS_KEY_ID").ok()?;
        let access_key_secret = std::env::var("OSS_ACCESS_KEY_SECRET").ok()?;
        let region = std::env::var("OSS_REGION").unwrap_or_else(|_| "cn-beijing".to_string());
        Some(Self { endpoint, bucket, access_key_id, access_key_secret, region })
    }
}

impl OssBackend {
    /// 创建 OSS 后端实例
    pub fn new(config: OssConfig) -> Self {
        let credentials = Credentials::new(
            &config.access_key_id,
            &config.access_key_secret,
            None, // no session token for permanent AK/SK
            None, // no expiry
            "flash-im-oss",
        );

        let url_prefix = format!(
            "https://{}.{}",
            config.bucket,
            config.endpoint.trim_start_matches("https://")
        );

        let s3_config = aws_sdk_s3::Config::builder()
            .region(Region::new(config.region))
            .endpoint_url(&config.endpoint)
            .credentials_provider(credentials)
            .force_path_style(false)
            .behavior_version_latest()
            .build();

        let client = Client::from_conf(s3_config);

        Self {
            client,
            bucket: config.bucket,
            url_prefix,
        }
    }

    /// 获取 S3 Client 引用（供 STS / HeadObject 等高级操作使用）
    pub fn client(&self) -> &Client {
        &self.client
    }

    /// 获取 bucket 名
    pub fn bucket(&self) -> &str {
        &self.bucket
    }
}

impl StorageBackend for OssBackend {
    async fn put(&self, path: &str, data: &[u8]) -> Result<(), std::io::Error> {
        self.client
            .put_object()
            .bucket(&self.bucket)
            .key(path)
            .body(ByteStream::from(data.to_vec()))
            .send()
            .await
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e.to_string()))?;
        Ok(())
    }

    async fn get(&self, path: &str) -> Result<Vec<u8>, std::io::Error> {
        let resp = self.client
            .get_object()
            .bucket(&self.bucket)
            .key(path)
            .send()
            .await
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e.to_string()))?;

        let bytes = resp.body.collect().await
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e.to_string()))?;
        Ok(bytes.to_vec())
    }

    async fn delete(&self, path: &str) -> Result<(), std::io::Error> {
        self.client
            .delete_object()
            .bucket(&self.bucket)
            .key(path)
            .send()
            .await
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e.to_string()))?;
        Ok(())
    }

    async fn exists(&self, path: &str) -> Result<bool, std::io::Error> {
        match self.client
            .head_object()
            .bucket(&self.bucket)
            .key(path)
            .send()
            .await
        {
            Ok(_) => Ok(true),
            Err(e) => {
                let service_err = e.into_service_error();
                if service_err.is_not_found() {
                    Ok(false)
                } else {
                    Err(std::io::Error::new(std::io::ErrorKind::Other, service_err.to_string()))
                }
            }
        }
    }
}
