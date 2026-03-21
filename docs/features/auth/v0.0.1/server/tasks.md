# Auth 模块 — Server 任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。
全局约束：单 crate 结构，PostgreSQL 直连，不拆 workspace。

---

## 执行顺序

1. ✅ 任务 1 — Cargo.toml 添加依赖
2. ✅ 任务 2 — 数据库迁移建表（依赖任务 1）
   - ✅ 2.1 创建迁移文件
   - ✅ 2.2 编写初始化脚本
   - ✅ 2.3 编写重置脚本
3. ✅ 任务 3 — state.rs 接入数据库连接池
   - ✅ 3.1 AppState 增加数据库连接池
   - ✅ 3.2 User 结构体定义
   - ✅ 3.3 create_app_state 接收 PgPool
4. ✅ 任务 4 — main.rs 连接数据库（依赖任务 3）
   - ✅ 4.1 加载环境变量
   - ✅ 4.2 创建连接池并传入 state
5. ✅ 任务 5 — model.rs 数据结构（无依赖，纯定义）
   - ✅ 5.1 LoginResponse 增加 has_password
   - ✅ 5.2 新增 PasswordRequest
   - ✅ 5.3 新增 MessageResponse
6. ✅ 任务 6 — handler.rs 核心逻辑（依赖任务 3、5）
   - ✅ 6.1 send_sms
   - ✅ 6.2 login 统一入口
   - ✅ 6.3 login_with_sms
   - ✅ 6.4 login_with_password
   - ✅ 6.5 set_password
   - ✅ 6.6 profile
   - ✅ 6.7 extract_user_id
7. ✅ 任务 7 — routes.rs 注册路由（依赖任务 6）
8. ✅ 编译验证 + 测试
   - ✅ 8.1 编译验证
   - ✅ 8.2 启动服务
   - ✅ 8.3 接口测试

---

## 任务 1：Cargo.toml — 添加依赖 `✅ 已完成`

文件：`server/Cargo.toml`

新增以下依赖：

```toml
sqlx = { version = "0.8", features = ["runtime-tokio", "postgres", "uuid", "chrono"] }
dotenvy = "0.15"
argon2 = "0.5"
chrono = { version = "0.4", features = ["serde"] }
```

- `sqlx` — PostgreSQL 异步驱动 + 连接池
- `dotenvy` — 从 .env 文件加载环境变量（DATABASE_URL, JWT_SECRET 等）
- `argon2` — 密码哈希
- `chrono` — 验证码过期时间判断

---

## 任务 2：数据库迁移 — 建表 `✅ 已完成`

文件：`server/migrations/` + `scripts/database/db_init.ps1` + `scripts/database/db_reset.ps1`

### 2.1 创建迁移文件 `✅`

使用 sqlx migrate 创建 design.md 中定义的 4 张表：
- `accounts` — 账户主体（BIGSERIAL 主键，status 字段预留封禁/注销）
- `user_profiles` — 用户资料（1:1 关联 accounts）
- `auth_credentials` — 认证凭据（1:N 关联 accounts，UNIQUE(auth_type, identifier)）
- `sms_codes` — 短信验证码（phone 主键，带 expires_at 过期时间）

SQL 定义详见 design.md 第 3 节。

### 2.2 编写初始化脚本 `✅`

`scripts/database/db_init.ps1`：
1. 检测 sqlx-cli 是否安装，未安装则 `cargo install sqlx-cli --no-default-features --features postgres`
2. 设置 `DATABASE_URL` 环境变量（默认 `postgres://postgres:postgres@localhost:5432/flash_im`）
3. 执行 `sqlx migrate run --source server/migrations`
4. 支持通过 `-DatabaseUrl` 参数自定义连接地址

用法：
```powershell
powershell -ExecutionPolicy Bypass -File scripts/database/db_init.ps1
```

### 2.3 编写重置脚本 `✅`

`scripts/database/db_reset.ps1`：
1. 断开目标数据库的所有活动连接（`pg_terminate_backend`）
2. `DROP DATABASE IF EXISTS` 删除数据库
3. `CREATE DATABASE` 重新创建
4. 调用 `db_init.ps1` 重新执行迁移

支持参数：`-PgHost`、`-Port`、`-User`、`-Password`、`-Database`，均有默认值。

用法：
```powershell
powershell -ExecutionPolicy Bypass -File scripts/database/db_reset.ps1
```

---

## 任务 3：state.rs — 共享状态接入数据库 `✅ 已完成`

文件：`server/src/state.rs`

### 3.1 AppState 增加数据库连接池 `✅`

```rust
pub struct AppState {
    pub db: PgPool,
    pub chat_tx: broadcast::Sender<String>,
}
```

### 3.2 User 结构体定义 `✅`

供 profile 接口返回：

```rust
pub struct User {
    pub user_id: i64,
    pub phone: String,
    pub nickname: String,
    pub avatar: String,
}
```

### 3.3 create_app_state 改为接收 PgPool 参数 `✅`

```rust
pub fn create_app_state(db: PgPool) -> Arc<AppState>
```

---

## 任务 4：main.rs — 启动时连接数据库 `✅ 已完成`

文件：`server/src/main.rs`

### 4.1 加载环境变量 `✅`

使用 `dotenvy::dotenv()` 从 .env 读取 `DATABASE_URL` 和 `SERVER_PORT`。

### 4.2 创建连接池并传入 state `✅`

```rust
let db = PgPoolOptions::new()
    .max_connections(10)
    .connect(&database_url)
    .await
    .expect("Failed to connect to database");

let state = state::create_app_state(db);
```

注意：启动失败要有明确的错误提示，不能静默。

---

## 任务 5：model.rs — 数据结构定义 `✅ 已完成`

文件：`server/src/auth/model.rs`

### 5.1 LoginResponse 增加 has_password `✅`

```rust
pub struct LoginResponse {
    pub token: String,
    pub user_id: i64,
    pub has_password: bool,  // 新增
}
```

### 5.2 新增 PasswordRequest `✅`

```rust
#[derive(Deserialize)]
pub struct PasswordRequest {
    pub new_password: String,
}
```

### 5.3 新增 MessageResponse（通用消息响应） `✅`

```rust
#[derive(Serialize)]
pub struct MessageResponse {
    pub message: String,
}
```

---

## 任务 6：handler.rs — 核心业务逻辑 `✅ 已完成`

文件：`server/src/auth/handler.rs`

### 6.1 send_sms — 发送验证码写入数据库 `✅`

签名：
```rust
pub async fn send_sms(
    State(state): State<Arc<AppState>>,
    Json(req): Json<SmsRequest>,
) -> Result<Json<SmsResponse>, StatusCode>
```

逻辑：
1. 校验手机号格式（11 位，1 开头），不合法返回 400
2. 生成 6 位随机验证码，过期时间 5 分钟
3. INSERT sms_codes，ON CONFLICT (phone) DO UPDATE 覆盖旧验证码
4. 返回验证码（测试阶段直接返回，生产环境改为发短信）

### 6.2 login — 统一登录入口 `✅`

根据 `LoginRequest.login_type` 分发到 `login_with_sms` 或 `login_with_password`。

### 6.3 login_with_sms — 短信验证码登录（登录即注册） `✅`

逻辑：
1. 查 sms_codes 表，校验验证码和过期时间
2. 验证通过后删除验证码（防止重放）
3. 调用 `find_or_create_user(phone)`：
   - 已有用户：查 credential 是否为 NULL，返回 `(user_id, has_password)`
   - 新用户：开事务，依次 INSERT accounts → user_profiles → auth_credentials（credential = NULL）
4. 生成 JWT，返回 `{ token, user_id, has_password }`

### 6.4 login_with_password — 密码登录 `✅`

逻辑：
1. 查 auth_credentials 表获取 credential
2. credential 为 NULL → 返回 401（未设置密码）
3. Argon2 验证密码
4. 生成 JWT，has_password 固定为 true

### 6.5 set_password — 设置密码（需 Token） `✅`

签名：
```rust
pub async fn set_password(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<PasswordRequest>,
) -> Result<Json<MessageResponse>, StatusCode>
```

逻辑：
1. `extract_user_id` 从 Token 解析 account_id
2. 校验 new_password 长度 ≥ 6，否则 400
3. Argon2 hash new_password
4. UPDATE auth_credentials SET credential = hash WHERE account_id AND auth_type = 'phone'
5. 返回 `{ message: "密码设置成功" }`

### 6.6 profile — 获取用户信息（需 Token） `✅`

逻辑：
1. `extract_user_id` 从 Token 解析 account_id
2. JOIN user_profiles + accounts 查询昵称、头像（校验 status = 0）
3. 查 auth_credentials 获取手机号
4. 返回 User 结构体

### 6.7 提取公共函数 extract_user_id `✅`

`profile` 和 `set_password` 都需要从 header 解析 Token，提取为：

```rust
fn extract_user_id(headers: &HeaderMap) -> Result<i64, StatusCode> {
    let token = headers
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or(StatusCode::UNAUTHORIZED)?;
    verify_token(token).map_err(|_| StatusCode::UNAUTHORIZED)
}
```

---

## 任务 7：routes.rs — 注册路由 `✅ 已完成`

文件：`server/src/auth/routes.rs`

```rust
.route("/auth/sms", post(send_sms))
.route("/auth/login", post(login))
.route("/auth/password", post(set_password))
.route("/user/profile", get(profile))
```

注意 import 要包含 `set_password`。


---

## 任务 8：编译验证 + 测试 `✅ 已完成`

### 8.1 编译验证 `✅`

```powershell
cargo build
```

确保无编译错误、无 warning（或 warning 可接受）。

### 8.2 启动服务 `✅`

```powershell
powershell -ExecutionPolicy Bypass -File scripts/server/start.ps1
```

确认控制台输出 `Database connected` 和监听地址。

### 8.3 接口测试 `✅`

测试路径：短信登录 → 检查 has_password=false → 设置密码 → 密码登录 → 检查 has_password=true

使用 playground 测试：
```powershell
flutter test client/test/playground/auth/auth_api_test.dart
```

验证点：
- 发送验证码：合法手机号返回 6 位验证码，非法手机号返回 400
- 短信登录：正确验证码登录成功，错误验证码返回 401，验证码使用后失效
- 登录即注册：新手机号首次登录自动创建账户
- 获取用户信息：有效 Token 返回用户资料，无 Token / 伪造 Token 返回 401
- 设置密码：密码长度 ≥ 6 设置成功，过短返回 400
- 密码登录：设置密码后可用密码登录，has_password=true
