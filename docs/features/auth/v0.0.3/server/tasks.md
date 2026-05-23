# 认证增强 — 服务端任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。

全局约束：
- 遵循 Rust 错误处理规范（AppError）
- GitHub API 请求超时 10 秒
- 新增依赖：reqwest、async-trait

---

## 执行顺序

1. ⬜ 任务 1 — 数据库迁移（login_logs 表 + 系统用户）
2. ⬜ 任务 2 — Cargo.toml 添加依赖
3. ⬜ 任务 3 — model.rs 新增请求/响应结构体
4. ⬜ 任务 4 — oauth/mod.rs OAuthProvider trait 定义
5. ⬜ 任务 5 — oauth/github.rs GitHubProvider 实现
6. ⬜ 任务 6 — login_log.rs 登录日志记录
7. ⬜ 任务 7 — welcome.rs 首次登录欢迎消息
8. ⬜ 任务 8 — handler.rs 新增 oauth_login + 修改 login
9. ⬜ 任务 9 — routes.rs + lib.rs 路由注册
10. ⬜ 任务 10 — .env 配置 + reset_db.py 更新
11. ⬜ 任务 11 — 编译验证

---

## 任务 1：数据库迁移 `⬜ 待处理`

文件：`server/migrations/20260523_010_login_logs.sql`（新建）

### 1.1 login_logs 表 `⬜`

```sql
CREATE TABLE login_logs (
    id          BIGSERIAL    PRIMARY KEY,
    account_id  BIGINT       NOT NULL REFERENCES accounts(id),
    login_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    ip          VARCHAR(45),
    platform    VARCHAR(20),
    device_name VARCHAR(100),
    device_id   VARCHAR(100),
    app_version VARCHAR(20)
);

CREATE INDEX idx_login_logs_account ON login_logs(account_id);
CREATE INDEX idx_login_logs_time ON login_logs(login_at DESC);
```

### 1.2 系统用户种子数据 `⬜`

```sql
INSERT INTO accounts (id, status, created_at, updated_at)
VALUES (0, 0, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_profiles (account_id, nickname, avatar, signature, updated_at)
VALUES (0, '闪讯助手', 'identicon:system', '我是闪讯官方助手', NOW())
ON CONFLICT (account_id) DO NOTHING;

SELECT setval('accounts_id_seq', GREATEST((SELECT MAX(id) FROM accounts), 1));
```

---

## 任务 2：Cargo.toml 添加依赖 `⬜ 待处理`

文件：`server/modules/flash-auth/Cargo.toml`（修改）

### 2.1 新增依赖 `⬜`

```toml
[dependencies]
# ... 现有依赖
reqwest = { version = "0.12", features = ["json"] }
async-trait = "0.1"
```

---

## 任务 3：model.rs 新增结构体 `⬜ 待处理`

文件：`server/modules/flash-auth/src/model.rs`（修改）

### 3.1 DeviceInfo `⬜`

```rust
#[derive(Deserialize, Default)]
pub struct DeviceInfo {
    pub platform: Option<String>,
    pub device_name: Option<String>,
    pub device_id: Option<String>,
    pub app_version: Option<String>,
}
```

### 3.2 OAuthLoginRequest `⬜`

```rust
#[derive(Deserialize)]
pub struct OAuthLoginRequest {
    pub code: String,
    #[serde(default)]
    pub device_info: DeviceInfo,
}
```

### 3.3 LoginRequest 新增 device_info 字段 `⬜`

```rust
#[derive(Deserialize)]
pub struct LoginRequest {
    pub phone: String,
    #[serde(rename = "type")]
    pub login_type: LoginType,
    pub credential: String,
    #[serde(default)]
    pub device_info: DeviceInfo,
}
```

---

## 任务 4：oauth/mod.rs — trait 定义 `⬜ 待处理`

文件：`server/modules/flash-auth/src/oauth/mod.rs`（新建）

### 4.1 OAuthUserInfo 结构体 `⬜`

```rust
pub struct OAuthUserInfo {
    pub provider: String,
    pub provider_id: String,
    pub nickname: String,
    pub avatar: Option<String>,
}
```

### 4.2 OAuthProvider trait `⬜`

```rust
#[async_trait::async_trait]
pub trait OAuthProvider: Send + Sync {
    async fn exchange_token(&self, code: &str) -> Result<String, flash_core::AppError>;
    async fn get_user_info(&self, token: &str) -> Result<OAuthUserInfo, flash_core::AppError>;
}
```

### 4.3 find_or_create_by_oauth 函数 `⬜`

```rust
/// 根据 OAuth 用户信息查找或创建账号
/// 返回 (account_id, is_new_user)
pub async fn find_or_create_by_oauth(
    db: &sqlx::PgPool,
    info: &OAuthUserInfo,
) -> Result<(i64, bool), flash_core::AppError>
```

逻辑步骤：
1. 查 auth_credentials WHERE auth_type=provider AND identifier=provider_id
2. 存在 → 返回 (account_id, false)
3. 不存在 → 事务内创建 account + user_profile + auth_credential → 返回 (account_id, true)

---

## 任务 5：oauth/github.rs — GitHubProvider `⬜ 待处理`

文件：`server/modules/flash-auth/src/oauth/github.rs`（新建）

### 5.1 GitHubProvider 结构体 `⬜`

```rust
pub struct GitHubProvider {
    client: reqwest::Client,
    client_id: String,
    client_secret: String,
}

impl GitHubProvider {
    pub fn from_env() -> Self
    // 从环境变量读取 GITHUB_CLIENT_ID、GITHUB_CLIENT_SECRET
    // reqwest::Client 设置 10 秒超时
}
```

### 5.2 实现 OAuthProvider trait `⬜`

**exchange_token**：
1. POST `https://github.com/login/oauth/access_token`
2. body: `{ client_id, client_secret, code }`
3. header: `Accept: application/json`
4. 解析响应拿 access_token
5. 失败返回 AppError::bad_request("GitHub 授权码无效或已过期")

**get_user_info**：
1. GET `https://api.github.com/user`
2. header: `Authorization: Bearer {token}`, `User-Agent: flash-im`
3. 解析响应拿 id、login、name、avatar_url
4. 构造 OAuthUserInfo { provider: "github", provider_id: id.to_string(), nickname: name 或 login, avatar: avatar_url }

---

## 任务 6：login_log.rs — 登录日志 `⬜ 待处理`

文件：`server/modules/flash-auth/src/login_log.rs`（新建）

### 6.1 record_login 函数 `⬜`

```rust
pub async fn record_login(
    db: &sqlx::PgPool,
    account_id: i64,
    ip: Option<&str>,
    device_info: &DeviceInfo,
) -> Result<(), sqlx::Error>
```

逻辑：INSERT INTO login_logs (account_id, ip, platform, device_name, device_id, app_version) VALUES (...)

### 6.2 is_first_login 函数 `⬜`

```rust
pub async fn is_first_login(db: &sqlx::PgPool, account_id: i64) -> Result<bool, sqlx::Error>
```

逻辑：SELECT 1 FROM login_logs WHERE account_id=$1 LIMIT 1，无记录返回 true

---

## 任务 7：welcome.rs — 欢迎消息 `⬜ 待处理`

文件：`server/modules/flash-auth/src/welcome.rs`（新建）

### 7.1 send_welcome 函数 `⬜`

```rust
pub async fn send_welcome(db: &sqlx::PgPool, user_id: i64) -> Result<(), sqlx::Error>
```

逻辑步骤：
1. 创建会话：INSERT INTO conversations (type, last_message_preview, last_message_at) VALUES (0, 欢迎文本, NOW()) RETURNING id
2. 添加成员：INSERT INTO conversation_members (conversation_id, user_id) VALUES (conv_id, 0), (conv_id, user_id)
3. 初始化序列号：INSERT INTO conversation_seq (conversation_id, current_seq) VALUES (conv_id, 1)
4. 插入消息：INSERT INTO messages (conversation_id, sender_id, seq, type, content) VALUES (conv_id, 0, 1, 0, 欢迎文本)

欢迎文本：`"你好！欢迎使用闪讯 IM，有任何问题可以在这里反馈 😊"`

---

## 任务 8：handler.rs — 新增 oauth_login + 修改 login `⬜ 待处理`

文件：`server/modules/flash-auth/src/handler.rs`（修改）

### 8.1 新增 github_login handler `⬜`

```rust
pub async fn github_login(
    State(state): State<Arc<AppState>>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(req): Json<OAuthLoginRequest>,
) -> Result<Json<LoginResponse>, AppError>
```

逻辑步骤：
1. 构造 GitHubProvider::from_env()
2. 调用 oauth_login_flow(provider, code, device_info, ip, db)
3. 返回 LoginResponse

### 8.2 抽取 oauth_login_flow 公共函数 `⬜`

```rust
async fn oauth_login_flow(
    provider: &dyn OAuthProvider,
    code: &str,
    device_info: &DeviceInfo,
    ip: Option<&str>,
    db: &PgPool,
) -> Result<LoginResponse, AppError>
```

逻辑步骤：
1. provider.exchange_token(code)
2. provider.get_user_info(token)
3. find_or_create_by_oauth(db, &info)
4. is_first_login(db, account_id) → 如果是 → send_welcome(db, account_id)
5. record_login(db, account_id, ip, device_info)
6. generate_token(account_id)

### 8.3 修改现有 login 函数 `⬜`

在登录成功后（签发 token 前）加两行：
1. `let is_first = is_first_login(&state.db, user_id).await.unwrap_or(false);`
2. `if is_first { let _ = send_welcome(&state.db, user_id).await; }`
3. `let _ = record_login(&state.db, user_id, Some(&extract_ip(&addr)), &req.device_info).await;`

### 8.4 extract_ip 辅助函数 `⬜`

```rust
fn extract_ip(addr: &SocketAddr) -> String
// 返回 addr.ip().to_string()
```

---

## 任务 9：routes.rs + lib.rs + main.rs `⬜ 待处理`

### 9.1 routes.rs 新增路由 `⬜`

文件：`server/modules/flash-auth/src/routes.rs`（修改）

```rust
.route("/auth/github", post(github_login))
```

需要 import：`use super::handler::github_login;`

### 9.2 lib.rs 导出新模块 `⬜`

文件：`server/modules/flash-auth/src/lib.rs`（修改）

```rust
mod oauth;
mod login_log;
mod welcome;
```

### 9.3 main.rs 启用 ConnectInfo `⬜`

文件：`server/src/main.rs`（修改）

将 `axum::serve(listener, app)` 改为：

```rust
axum::serve(listener, app.into_make_service_with_connect_info::<std::net::SocketAddr>())
```

这样 handler 才能通过 `ConnectInfo<SocketAddr>` 提取客户端 IP。

---

## 任务 10：配置更新 `⬜ 待处理`

### 10.1 server/.env 新增 `⬜`

```env
GITHUB_CLIENT_ID=你的client_id
GITHUB_CLIENT_SECRET=你的client_secret
```

### 10.2 scripts/server/reset_db.py 更新迁移列表 `⬜`

在 MIGRATIONS 列表末尾添加：
```python
"20260523_010_login_logs.sql",
```

---

## 任务 11：编译验证 `⬜ 待处理`

### 11.1 cargo build `⬜`

```bash
cd server && cargo build
```

期望：编译通过。

### 11.2 cargo clippy `⬜`

```bash
cd server && cargo clippy --workspace -- -W clippy::all
```

期望：无新增 warning。

### 11.3 数据库重置验证 `⬜`

```bash
python scripts/server/reset_db.py
```

期望：所有迁移执行成功，系统用户存在。
