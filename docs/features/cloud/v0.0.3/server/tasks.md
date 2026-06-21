# 云空间 OSS 存储 + 订阅兑换 — 后端任务清单

基于 server/design.md，拆解为可逐条执行的任务。

全局约束：
- 错误处理用 AppError（flash-core）
- Repository 层纯 SQL，Service 层编排逻辑
- STS 签发用 reqwest 直接调阿里云 HTTP API（不用 aws-sdk-sts）
- OssBackend 已完成（backend/oss.rs），本次复用其 client 做 head_object

---

## 执行顺序

1. ✅ 任务 1 — 新建 app-subscription 模块骨架（无依赖）
2. ✅ 任务 2 — 数据库建表 SQL（无依赖）
3. ✅ 任务 3 — model.rs 数据结构（依赖任务 1）
4. ✅ 任务 4 — repository.rs 数据访问（依赖任务 3）
5. ✅ 任务 5 — service.rs 业务逻辑（依赖任务 4）
6. ✅ 任务 6 — api.rs 路由（依赖任务 5）
7. ✅ 任务 7 — app-storage 新增 STS 签发（无依赖）
8. ✅ 任务 8 — app-storage 新增 upload-token + confirm-upload 接口（依赖任务 7）
9. ✅ 任务 9 — main.rs 注册路由（依赖任务 6、8）
10. ✅ 任务 10 — 编译验证 + 测试脚本

---

## 任务 1：新建 app-subscription 模块骨架 `⬜ 待处理`

### 1.1 创建 Cargo.toml `⬜`

文件：`server/modules/app-subscription/Cargo.toml`（新建）

```toml
[package]
name = "app-subscription"
version = "0.1.0"
edition = "2024"

[dependencies]
axum.workspace = true
tokio.workspace = true
serde.workspace = true
serde_json.workspace = true
chrono.workspace = true
sqlx.workspace = true
flash-core = { path = "../flash-core" }
```

### 1.2 创建 lib.rs `⬜`

文件：`server/modules/app-subscription/src/lib.rs`（新建）

```rust
pub mod model;
pub mod repository;
pub mod service;
mod api;

pub use api::router as subscription_routes;
pub use service::SubscriptionService;
```

### 1.3 注册到 workspace `⬜`

文件：`server/Cargo.toml`（修改）

workspace.members 增加 `"modules/app-subscription"`
[dependencies] 增加 `app-subscription = { path = "modules/app-subscription" }`

---

## 任务 2：数据库建表 `⬜ 待处理`

文件：`server/migrations/20260621_subscription_tables.sql`（新建）

```sql
CREATE TABLE subscription_plans (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    storage_bytes BIGINT NOT NULL,
    features JSONB NOT NULL DEFAULT '{}',
    price_cents INT NOT NULL DEFAULT 0,
    period_days INT NOT NULL DEFAULT 30,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_subscriptions (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    plan_id INT NOT NULL REFERENCES subscription_plans(id),
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    source VARCHAR(50) NOT NULL DEFAULT 'redeem',
    original_transaction_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE redeem_codes (
    id SERIAL PRIMARY KEY,
    code VARCHAR(32) UNIQUE NOT NULL,
    plan_id INT NOT NULL REFERENCES subscription_plans(id),
    duration_days INT NOT NULL DEFAULT 30,
    max_uses INT NOT NULL DEFAULT 1,
    used_count INT NOT NULL DEFAULT 0,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_subscriptions_user ON user_subscriptions(user_id, status);
CREATE INDEX idx_redeem_codes_code ON redeem_codes(code);

-- 初始计划
INSERT INTO subscription_plans (code, name, storage_bytes, features, price_cents, period_days)
VALUES ('cloud_pro', '云空间 Pro', 1073741824, '{"oss_upload": true}', 99, 30);

-- 测试兑换码（10 次可用）
INSERT INTO redeem_codes (code, plan_id, duration_days, max_uses)
VALUES ('TEST-PRO-2026', 1, 30, 10);
```

执行方式：`psql -d flash_im -f migrations/20260621_subscription_tables.sql`

---

## 任务 3：model.rs 数据结构 `⬜ 待处理`

文件：`server/modules/app-subscription/src/model.rs`（新建）

```rust
#[derive(Debug, Clone, sqlx::FromRow, Serialize)]
pub struct SubscriptionPlan {
    pub id: i32,
    pub code: String,
    pub name: String,
    pub storage_bytes: i64,
    pub features: serde_json::Value,
    pub price_cents: i32,
    pub period_days: i32,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, sqlx::FromRow, Serialize)]
pub struct UserSubscription {
    pub id: i32,
    pub user_id: i64,
    pub plan_id: i32,
    pub status: String,
    pub starts_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
    pub source: String,
    pub original_transaction_id: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct RedeemCode {
    pub id: i32,
    pub code: String,
    pub plan_id: i32,
    pub duration_days: i32,
    pub max_uses: i32,
    pub used_count: i32,
    pub expires_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
}
```

---

## 任务 4：repository.rs 数据访问 `⬜ 待处理`

文件：`server/modules/app-subscription/src/repository.rs`（新建）

方法清单：

```rust
pub struct SubRepo;

impl SubRepo {
    /// 查询兑换码
    pub async fn find_redeem_code(db: &PgPool, code: &str) -> Result<Option<RedeemCode>, sqlx::Error>

    /// 兑换码 used_count +1
    pub async fn increment_redeem_used(db: &PgPool, code_id: i32) -> Result<(), sqlx::Error>

    /// 查询计划
    pub async fn find_plan_by_id(db: &PgPool, plan_id: i32) -> Result<Option<SubscriptionPlan>, sqlx::Error>

    /// 创建用户订阅
    pub async fn create_subscription(db: &PgPool, user_id: i64, plan_id: i32, duration_days: i32, source: &str) -> Result<UserSubscription, sqlx::Error>

    /// 查询用户活跃订阅
    pub async fn find_active_subscription(db: &PgPool, user_id: i64) -> Result<Option<UserSubscription>, sqlx::Error>
    // SQL: WHERE user_id = $1 AND status = 'active' AND expires_at > NOW() ORDER BY expires_at DESC LIMIT 1

    /// 计算用户订阅总配额
    pub async fn sum_active_storage(db: &PgPool, user_id: i64) -> Result<i64, sqlx::Error>
    // SQL: SELECT COALESCE(SUM(p.storage_bytes), 0::BIGINT) FROM user_subscriptions s JOIN subscription_plans p ON s.plan_id = p.id WHERE s.user_id = $1 AND s.status = 'active' AND s.expires_at > NOW()
}
```

---

## 任务 5：service.rs 业务逻辑 `⬜ 待处理`

文件：`server/modules/app-subscription/src/service.rs`（新建）

```rust
pub struct SubscriptionService {
    db: PgPool,
}

impl SubscriptionService {
    pub fn new(db: PgPool) -> Self

    /// 兑换码兑换
    /// 步骤：1. 查码有效性 2. 创建订阅 3. used_count+1 4. 重算配额 5. 返回
    pub async fn redeem(&self, user_id: i64, code: &str) -> Result<RedeemResult, AppError>

    /// 查询订阅状态 + 是否可 OSS 上传
    pub async fn get_status(&self, user_id: i64) -> Result<SubscriptionStatus, AppError>

    /// 重算用户配额（100MB + 订阅配额）并更新 user_storage_quota
    async fn recalculate_quota(&self, user_id: i64) -> Result<(i64, i64), AppError>
}
```

---

## 任务 6：api.rs 路由 `⬜ 待处理`

文件：`server/modules/app-subscription/src/api.rs`（新建）

```rust
pub fn router(service: Arc<SubscriptionService>) -> Router {
    Router::new()
        .route("/api/subscriptions/redeem", post(redeem_handler))
        .route("/api/subscriptions/status", get(status_handler))
        .with_state(service)
}

/// POST /api/subscriptions/redeem
async fn redeem_handler(State(svc): State<Arc<SubscriptionService>>, headers: HeaderMap, Json(body): Json<RedeemRequest>) -> Result<Json<...>, AppError>

/// GET /api/subscriptions/status
async fn status_handler(State(svc): State<Arc<SubscriptionService>>, headers: HeaderMap) -> Result<Json<...>, AppError>
```

---

## 任务 7：STS 签发逻辑 `⬜ 待处理`

文件：`server/modules/app-storage/src/sts.rs`（新建）

阿里云 STS AssumeRole 的 HTTP 调用封装：

```rust
pub struct StsConfig {
    pub access_key_id: String,
    pub access_key_secret: String,
    pub role_arn: String,
    pub endpoint: String,  // https://sts.aliyuncs.com
}

pub struct StsToken {
    pub access_key_id: String,
    pub access_key_secret: String,
    pub security_token: String,
    pub expiration: String,
}

impl StsConfig {
    pub fn from_env() -> Option<Self>

    /// 调 AssumeRole，限定路径前缀
    pub async fn assume_role(&self, session_name: &str, policy_json: &str, duration_secs: u32) -> Result<StsToken, ...>
}
```

逻辑步骤：
1. 构造 AssumeRole 请求参数
2. 用 AK/SK 签名（阿里云签名 v1）
3. POST 到 https://sts.aliyuncs.com
4. 解析响应中的 Credentials

---

## 任务 8：upload-token + confirm-upload 接口 `⬜ 待处理`

文件：`server/modules/app-storage/src/api.rs`（修改）

### 8.1 upload-token 接口 `⬜`

```rust
/// POST /api/storage/upload-token
async fn upload_token_handler(...)
```

逻辑步骤：
1. extract_user_id
2. 查 user_subscriptions 是否有活跃订阅（调 app-subscription 的 service 或直接查库）
3. 检查配额充足
4. 生成 object_key（`users/{uid}/original/{date}/{uuid}.{ext}`）
5. 构造 STS Policy JSON（限定 bucket + object_key 前缀）
6. 调 STS assume_role
7. 返回临时凭证 + object_key + url

### 8.2 confirm-upload 接口 `⬜`

```rust
/// POST /api/storage/confirm-upload
async fn confirm_upload_handler(...)
```

逻辑步骤：
1. extract_user_id
2. 用 OssBackend.exists(object_key) 验证文件已上传
3. 插入 file_objects 记录（storage_path = object_key, storage_backend = 'oss'）
4. 扣减配额
5. WS 通知配额变更
6. 返回 file_id + 完整 URL

---

## 任务 9：main.rs 注册路由 `⬜ 待处理`

文件：`server/src/main.rs`（修改）

### 9.1 初始化 SubscriptionService `⬜`

```rust
let subscription_service = Arc::new(SubscriptionService::new(db.clone()));
```

### 9.2 注册路由 `⬜`

```rust
.merge(subscription_routes(subscription_service))
```

### 9.3 传递 OssBackend 到 storage 路由 `⬜`

upload-token 和 confirm-upload 需要访问 OssBackend 和 StsConfig。
在 StorageService 或独立 State 中持有 OssBackend 引用。

---

## 任务 10：编译验证 + 测试 `⬜ 待处理`

### 10.1 cargo build `⬜`

```bash
cd server && cargo build
```

### 10.2 建表 `⬜`

```bash
psql -d flash_im -f migrations/20260621_subscription_tables.sql
```

### 10.3 启动服务 + 测试兑换 `⬜`

```bash
python scripts/server/start.py
# 另一个终端：
curl -X POST http://localhost:9600/api/subscriptions/redeem \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"code": "TEST-PRO-2026"}'
```

### 10.4 测试 upload-token `⬜`

```bash
curl -X POST http://localhost:9600/api/storage/upload-token \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"file_name": "test.jpg", "file_size": 1024, "mime_type": "image/jpeg", "hash": "abc123"}'
```
