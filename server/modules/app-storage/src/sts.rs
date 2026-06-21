//! 阿里云 STS AssumeRole 签发临时凭证

use base64::Engine;
use base64::engine::general_purpose::STANDARD as BASE64;
use chrono::Utc;
use hmac::{Hmac, Mac};
use percent_encoding::{utf8_percent_encode, NON_ALPHANUMERIC};
use rand::Rng;
use serde::Deserialize;
use sha1::Sha1;

/// STS 配置
#[derive(Debug, Clone)]
pub struct StsConfig {
    pub access_key_id: String,
    pub access_key_secret: String,
    pub role_arn: String,
}

/// STS 临时凭证
#[derive(Debug, Clone, serde::Serialize)]
pub struct StsToken {
    pub access_key_id: String,
    pub access_key_secret: String,
    pub security_token: String,
    pub expiration: String,
}

impl StsConfig {
    /// 从环境变量读取
    pub fn from_env() -> Option<Self> {
        let access_key_id = std::env::var("OSS_ACCESS_KEY_ID").ok()?;
        let access_key_secret = std::env::var("OSS_ACCESS_KEY_SECRET").ok()?;
        let role_arn = std::env::var("OSS_STS_ROLE_ARN").ok()?;
        Some(Self { access_key_id, access_key_secret, role_arn })
    }

    /// 调用 AssumeRole 获取临时凭证
    ///
    /// - `session_name`: 会话标识，如 "upload-user-1"
    /// - `policy_json`: 可选的内联策略 JSON，进一步限制权限
    /// - `duration_secs`: Token 有效期（秒），最小 900，最大 3600
    pub async fn assume_role(
        &self,
        session_name: &str,
        policy_json: Option<&str>,
        duration_secs: u32,
    ) -> Result<StsToken, String> {
        let timestamp = Utc::now().format("%Y-%m-%dT%H:%M:%SZ").to_string();
        let nonce: u64 = rand::rng().random();
        let duration_str = duration_secs.to_string();
        let nonce_str = nonce.to_string();

        let mut params: Vec<(&str, &str)> = vec![
            ("Action", "AssumeRole"),
            ("Format", "JSON"),
            ("Version", "2015-04-01"),
            ("AccessKeyId", &self.access_key_id),
            ("SignatureMethod", "HMAC-SHA1"),
            ("SignatureVersion", "1.0"),
            ("SignatureNonce", &nonce_str),
            ("Timestamp", &timestamp),
            ("RoleArn", &self.role_arn),
            ("RoleSessionName", session_name),
            ("DurationSeconds", &duration_str),
        ];

        if let Some(policy) = policy_json {
            params.push(("Policy", policy));
        }

        // 排序
        params.sort_by_key(|&(k, _)| k);

        // 构造 canonicalized query string
        let query_string: String = params.iter()
            .map(|(k, v)| format!("{}={}", encode(k), encode(v)))
            .collect::<Vec<_>>()
            .join("&");

        // 构造待签名字符串
        let string_to_sign = format!("POST&{}&{}", encode("/"), encode(&query_string));

        // HMAC-SHA1 签名
        let signing_key = format!("{}&", self.access_key_secret);
        let mut mac = Hmac::<Sha1>::new_from_slice(signing_key.as_bytes())
            .map_err(|e| format!("HMAC error: {}", e))?;
        mac.update(string_to_sign.as_bytes());
        let signature = BASE64.encode(mac.finalize().into_bytes());

        // 构造请求 body
        let mut body_params = params.iter()
            .map(|(k, v)| format!("{}={}", encode(k), encode(v)))
            .collect::<Vec<_>>();
        body_params.push(format!("Signature={}", encode(&signature)));
        let body = body_params.join("&");

        // 发送请求
        let client = reqwest::Client::new();
        let resp = client
            .post("https://sts.aliyuncs.com/")
            .header("Content-Type", "application/x-www-form-urlencoded")
            .body(body)
            .send()
            .await
            .map_err(|e| format!("STS request failed: {}", e))?;

        let status = resp.status();
        let text = resp.text().await.map_err(|e| format!("Read body failed: {}", e))?;

        if !status.is_success() {
            return Err(format!("STS returned {}: {}", status, text));
        }

        let response: AssumeRoleResponse = serde_json::from_str(&text)
            .map_err(|e| format!("Parse STS response failed: {} body: {}", e, text))?;

        Ok(StsToken {
            access_key_id: response.credentials.access_key_id,
            access_key_secret: response.credentials.access_key_secret,
            security_token: response.credentials.security_token,
            expiration: response.credentials.expiration,
        })
    }
}

/// URL 编码（阿里云要求的严格编码）
fn encode(s: &str) -> String {
    utf8_percent_encode(s, NON_ALPHANUMERIC)
        .to_string()
        .replace('+', "%20")
        .replace('*', "%2A")
        .replace("%7E", "~")
}

// ─── 响应解析 ───

#[derive(Deserialize)]
#[serde(rename_all = "PascalCase")]
struct AssumeRoleResponse {
    credentials: Credentials,
}

#[derive(Deserialize)]
#[serde(rename_all = "PascalCase")]
struct Credentials {
    access_key_id: String,
    access_key_secret: String,
    security_token: String,
    expiration: String,
}
