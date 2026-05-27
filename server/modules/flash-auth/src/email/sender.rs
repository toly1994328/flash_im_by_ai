use flash_core::AppError;
use lettre::message::header::ContentType;
use lettre::transport::smtp::authentication::Credentials;
use lettre::{Message, SmtpTransport, Transport};

/// SMTP 邮箱配置
pub struct SmtpConfig {
    pub username: String,
    pub password: String,
    pub host: String,
}

impl SmtpConfig {
    pub fn from_env() -> Self {
        Self {
            username: std::env::var("EMAIL_USERNAME").expect("EMAIL_USERNAME must be set"),
            password: std::env::var("EMAIL_PASSWORD").expect("EMAIL_PASSWORD must be set"),
            host: std::env::var("EMAIL_SMTP_HOST").expect("EMAIL_SMTP_HOST must be set"),
        }
    }
}

/// 是否为 debug 模式（不真正发邮件）
pub fn is_debug_mode() -> bool {
    std::env::var("EMAIL_ENV").unwrap_or_default() == "debug"
}

/// 发送验证码邮件
pub fn send_code(config: &SmtpConfig, to: &str, code: &str) -> Result<(), AppError> {
    let body = format!("欢迎使用闪讯，您的验证码为：{code}，5 分钟内有效。请勿泄露给他人。");

    let email = Message::builder()
        .from(config.username.parse().map_err(|e| AppError::internal(e, "email_from_parse"))?)
        .to(to.parse().map_err(|e| AppError::internal(e, "email_to_parse"))?)
        .subject("闪讯 验证码")
        .header(ContentType::TEXT_PLAIN)
        .body(body)
        .map_err(|e| AppError::internal(e, "email_build"))?;

    let creds = Credentials::new(config.username.clone(), config.password.clone());

    let mailer = SmtpTransport::relay(&config.host)
        .map_err(|e| AppError::internal(e, "smtp_relay"))?
        .port(465)
        .credentials(creds)
        .build();

    mailer.send(&email).map_err(|e| AppError::internal(e, "smtp_send"))?;

    Ok(())
}
