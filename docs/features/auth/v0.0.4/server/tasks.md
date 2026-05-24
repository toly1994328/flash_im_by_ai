# 认证增强（Apple 登录 + 邮箱登录）— 后端任务清单

基于 server/design.md 设计，列出需要创建/修改的具体细节。

全局约束：
- 错误处理使用 AppError，不返回裸 StatusCode
- OAuth 登录复用 OAuthProvider trait + find_or_create_by_oauth
- 邮件发送使用 lettre crate
- 环境变量通过 std::env::var 读取

---

## 执行顺序

1. ⬜ 任务 1 — 数据库迁移（email_codes 表）
2. ⬜ 任务 2 — 添加 lettre 依赖
3. ⬜ 任务 3 — 邮件发送器（email/sender.rs）
4. ⬜ 任务 4 — 邮件模块入口（email/mod.rs）
5. ⬜ 任务 5 — Apple OAuth Provider（oauth/apple.rs）
6. ⬜ 任务 6 — 扩展 model.rs（新增请求结构体 + LoginType）
7. ⬜ 任务 7 — 扩展 handler.rs（新增 handler + 扩展 login）
8. ⬜ 任务 8 — 扩展 routes.rs（新增路由）
9. ⬜ 任务 9 — 环境变量配置（.env）
10. ⬜ 任务 10 — 编译验证

---

## 任务 1：数据库迁移 `⬜ 待处理`

文件：`server/migrations/20260524_011_email_codes.sql`（新建）

### 1.1 创建 email_codes 表 `⬜`

```sql
CREATE TABLE IF NOT EXISTS email_codes (
    email       VARCHAR(255) PRIMARY KEY,
    code        VARCHAR(6) NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    request_ip  VARCHAR(45),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 任务 2：添加 lettre 依赖 `⬜ 待处理`

文件：`server/modules/flash-auth/Cargo.toml`（修改）

### 2.1 dependencies 新增 lettre `⬜`

```toml
lettre = { version = "0.11", features = ["tokio1-native-tls", "builder"] }
```

---

## 任务 3：邮件发送器 `⬜ 待处理`

文件：`server/modules/flash-auth/src/email/sender.rs`（新建）

### 3.1 SmtpConfig 结构体 `⬜`

```rust
pub struct SmtpConfig {
    pub username: String,
    pub password: String,
    pub host: String,
}

impl SmtpConfig {
    pub fn from_env() -> Self { ... }
}
```

从环境变量读取：`EMAIL_USERNAME`、`EMAIL_PASSWORD`、`EMAIL_SMTP_HOST`

### 3.2 send_code 函数 `⬜`

```rust
pub async fn send_code(config: &SmtpConfig, to: &str, code: &str, app_name: &str) -> Result<(), AppError>
```

逻辑步骤：
1. 构建邮件（from=config.username, to, subject="{app_name} 验证码", body="验证码：{code}，5 分钟内有效"）
2. 创建 SmtpTransport（relay host, port 465, credentials）
3. 发送邮件
4. 失败时返回 AppError::internal

### 3.3 is_debug 判断 `⬜`

```rust
pub fn is_debug_mode() -> bool {
    std::env::var("EMAIL_ENV").unwrap_or_default() == "debug"
}
```

---

## 任务 4：邮件模块入口 `⬜ 待处理`

文件：`server/modules/flash-auth/src/email/mod.rs`（新建）

### 4.1 模块声明 `⬜`

```rust
pub mod sender;
```

同时在 `lib.rs` 中添加 `mod email;`

---

## 任务 5：Apple OAuth Provider `⬜ 待处理`

文件：`server/modules/flash-auth/src/oauth/apple.rs`（新建）

### 5.1 AppleProvider 结构体 `⬜`

```rust
pub struct AppleProvider {
    client: reqwest::Client,
    bundle_id: String,
}

impl AppleProvider {
    pub fn from_env() -> Self { ... }
}
```

从环境变量读取：`APPLE_BUNDLE_ID`

### 5.2 实现 OAuthProvider trait `⬜`

```rust
#[async_trait::async_trait]
impl OAuthProvider for AppleProvider {
    async fn exchange_token(&self, identity_token: &str) -> Result<String, AppError> { ... }
    async fn get_user_info(&self, token: &str) -> Result<OAuthUserInfo, AppError> { ... }
}
```

**exchange_token** 逻辑（Apple 不需要换 token，直接验证 identity_token）：
1. 请求 `https://appleid.apple.com/auth/keys` 获取 JWKS
2. 解析 identity_token 的 header，取 kid
3. 从 JWKS 中找到对应 kid 的公钥
4. 用 jsonwebtoken 验证签名（RS256）
5. 校验 iss = `https://appleid.apple.com`
6. 校验 aud = bundle_id
7. 返回 identity_token 本身（后续 get_user_info 再解析）

**get_user_info** 逻辑：
1. 解码 identity_token 的 payload（不验证，因为 exchange_token 已验证）
2. 提取 sub 字段作为 provider_id
3. 提取 email 字段（可能为空）
4. nickname 用 email 前缀或 "Apple 用户"

### 5.3 JWKS 响应结构体 `⬜`

```rust
#[derive(Deserialize)]
struct JwksResponse { keys: Vec<JwkKey> }

#[derive(Deserialize)]
struct JwkKey {
    kty: String,
    kid: String,
    alg: String,
    n: String,
    e: String,
}
```

### 5.4 oauth/mod.rs 添加 pub mod apple `⬜`

---

## 任务 6：扩展 model.rs `⬜ 待处理`

文件：`server/modules/flash-auth/src/model.rs`（修改）

### 6.1 LoginType 新增 Email 变体 `⬜`

```rust
#[derive(Deserialize, Debug)]
#[serde(rename_all = "snake_case")]
pub enum LoginType {
    Sms,
    Password,
    Email,
}
```

### 6.2 新增 EmailCodeRequest `⬜`

```rust
#[derive(Deserialize)]
pub struct EmailCodeRequest {
    pub email: String,
}
```

### 6.3 新增 EmailCodeResponse `⬜`

```rust
#[derive(Serialize)]
pub struct EmailCodeResponse {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub code: Option<String>,
    pub message: String,
}
```

### 6.4 新增 AppleLoginRequest `⬜`

```rust
#[derive(Deserialize)]
pub struct AppleLoginRequest {
    pub identity_token: String,
    #[serde(default)]
    pub device_info: DeviceInfo,
}
```

---

## 任务 7：扩展 handler.rs `⬜ 待处理`

文件：`server/modules/flash-auth/src/handler.rs`（修改）

### 7.1 新增 send_email_code handler `⬜`

```rust
pub async fn send_email_code(
    State(state): State<Arc<AppState>>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(req): Json<EmailCodeRequest>,
) -> Result<Json<EmailCodeResponse>, AppError>
```

逻辑步骤：
1. 校验邮箱格式（包含 @ 和 .）
2. 获取客户端 IP
3. 查 email_codes 表，检查该邮箱或该 IP 的 created_at 是否在 60 秒内
4. 如果频率超限，返回 AppError::too_many_requests（或 bad_request 带提示）
5. 生成 6 位随机验证码
6. UPSERT email_codes 表（email, code, expires_at=now+5min, request_ip, created_at=now）
7. 如果 is_debug_mode()，直接返回 code
8. 否则调用 sender::send_code 发送邮件
9. 返回 EmailCodeResponse

### 7.2 新增 apple_login handler `⬜`

```rust
pub async fn apple_login(
    State(state): State<Arc<AppState>>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(req): Json<AppleLoginRequest>,
) -> Result<Json<LoginResponse>, AppError>
```

逻辑步骤：
1. 创建 AppleProvider::from_env()
2. 调用 oauth_login_flow(&provider, &req.identity_token, &req.device_info, ip, &state.db)
3. 返回 LoginResponse

### 7.3 扩展 login handler 支持 Email `⬜`

在 `login` 函数中，将 `validate_phone` 校验改为按 login_type 区分：

```rust
// 仅 sms 和 password 类型校验手机号
if matches!(req.login_type, LoginType::Sms | LoginType::Password) {
    validate_phone(&req.phone)?;
}
```

然后在 match 中新增：

```rust
LoginType::Email => login_with_email(&state, &req).await,
```

### 7.4 新增 login_with_email 内部函数 `⬜`

```rust
async fn login_with_email(
    state: &Arc<AppState>,
    req: &LoginRequest,
) -> Result<Json<LoginResponse>, AppError>
```

逻辑步骤：
1. 查 email_codes 表（WHERE email = req.phone）
2. 如果验证码匹配且未过期 → 删除记录 → find_or_create_user_by_email
3. 如果验证码不匹配 → 尝试密码校验（查 auth_credentials WHERE auth_type='email' AND identifier=email）
4. 都失败 → 返回 401

### 7.5 新增 find_or_create_user_by_email 内部函数 `⬜`

```rust
async fn find_or_create_user_by_email(
    state: &Arc<AppState>,
    email: &str,
) -> Result<(i64, bool), AppError>
```

逻辑同 find_or_create_user，但：
- auth_type = 'email'
- identifier = email
- nickname = 邮箱 @ 前缀

---

## 任务 8：扩展 routes.rs `⬜ 待处理`

文件：`server/modules/flash-auth/src/routes.rs`（修改）

### 8.1 新增路由 `⬜`

```rust
use super::handler::{send_sms, login, github_login, apple_login, send_email_code};

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/auth/sms", post(send_sms))
        .route("/auth/login", post(login))
        .route("/auth/github", post(github_login))
        .route("/auth/apple", post(apple_login))
        .route("/auth/email/code", post(send_email_code))
}
```

---

## 任务 9：环境变量配置 `⬜ 待处理`

文件：`server/.env`（修改）

### 9.1 新增邮箱和 Apple 配置 `⬜`

```env
# 邮箱验证码
EMAIL_ENV=debug
EMAIL_USERNAME=1981462002@qq.com
EMAIL_PASSWORD=your_smtp_auth_code
EMAIL_SMTP_HOST=smtp.qq.com

# Apple 登录
APPLE_BUNDLE_ID=com.toly1994.flashIm
```

---

## 任务 10：编译验证 `⬜ 待处理`

### 10.1 cargo build `⬜`

```bash
cd server
cargo build
```

确认零错误。

### 10.2 数据库迁移 `⬜`

```bash
python scripts/server/start.py
```

确认 email_codes 表创建成功。

### 10.3 接口冒烟测试 `⬜`

- POST /auth/email/code `{"email": "test@example.com"}` → 返回 code（debug 模式）
- POST /auth/login `{"phone": "test@example.com", "type": "email", "credential": "123456"}` → 返回 token
- 60 秒内重复请求 /auth/email/code → 返回频率限制提示
