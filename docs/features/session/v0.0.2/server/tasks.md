# session v0.0.2 — 服务端任务清单

基于 [design.md](./design.md) 设计，将 user 模块提取为独立 crate，新增资料编辑和密码管理接口。

全局约束：
- 所有 crate 使用 `edition = "2024"`
- 公共依赖通过 `workspace.dependencies` 管理
- 每个 crate 只暴露一个 `pub fn router()` 作为公开 API
- `extract_user_id` 统一从 `flash_core::jwt` 引用，不在各模块重复实现
- 密码哈希使用 argon2

---

## 执行顺序

1. ✅ 任务 1 — 数据库迁移：user_profiles 新增 signature 字段（无依赖）
   - ✅ 1.1 修改迁移脚本
   - ✅ 1.2 重置数据库
2. ✅ 任务 2 — flash-core 更新：User 新增 signature + extract_user_id 提取（无依赖）
   - ✅ 2.1 User 结构体新增 signature
   - ✅ 2.2 extract_user_id 提取到 jwt.rs
   - ✅ 2.3 Cargo.toml 确认依赖
3. ✅ 任务 3 — flash-user crate 创建：Cargo.toml + 项目骨架（依赖任务 2）
   - ✅ 3.1 创建 Cargo.toml
   - ✅ 3.2 创建目录结构
4. ✅ 任务 4 — flash-user model.rs：请求/响应结构体（依赖任务 3）
   - ✅ 4.1 UpdateProfileRequest
   - ✅ 4.2 SetPasswordRequest
   - ✅ 4.3 ChangePasswordRequest
   - ✅ 4.4 MessageResponse
5. ✅ 任务 5 — flash-user handler.rs：四个接口实现（依赖任务 2、4）
   - ✅ 5.1 profile (GET)
   - ✅ 5.2 update_profile (PUT)
   - ✅ 5.3 set_password (POST)
   - ✅ 5.4 change_password (PUT)
   - ✅ 5.5 find_user_by_id 辅助函数
6. ✅ 任务 6 — flash-user routes.rs + lib.rs：路由与公开 API（依赖任务 5）
   - ✅ 6.1 routes.rs
   - ✅ 6.2 lib.rs
7. ✅ 任务 7 — flash-auth 清理：删除迁出的代码（依赖任务 2、6）
   - ✅ 7.1 handler.rs 删除 set_password + extract_user_id
   - ✅ 7.2 routes.rs 删除 /auth/password
   - ✅ 7.3 model.rs 删除 PasswordRequest + MessageResponse
8. ✅ 任务 8 — flash-auth 默认头像：identicon 标记（依赖任务 7）
   - ✅ 8.1 修改 find_or_create_user 默认头像
9. ✅ 任务 9 — workspace 配置：Cargo.toml 新增 flash-user（依赖任务 3）
   - ✅ 9.1 workspace members 新增
   - ✅ 9.2 主 binary 新增依赖
10. ✅ 任务 10 — main.rs 更新：集成 flash-user，删除旧 user 模块（依赖任务 6、9）
    - ✅ 10.1 删除 mod user
    - ✅ 10.2 替换路由
    - ✅ 10.3 删除旧文件
11. ✅ 任务 11 — 编译验证 + 测试路径（依赖全部）

---

## 任务 1：数据库迁移 — user_profiles 新增 signature `✅ 已完成`

开发阶段使用重置数据库的方式，直接修改建表脚本。

### 1.1 修改迁移脚本 `✅`

文件：`server/migrations/20250320_001_auth.sql`（修改）

在 `user_profiles` 表定义中新增 `signature` 字段：

```sql
CREATE TABLE user_profiles (
    account_id BIGINT       PRIMARY KEY REFERENCES accounts(id),
    nickname   VARCHAR(50)  NOT NULL,
    avatar     VARCHAR(500),
    signature  VARCHAR(100) DEFAULT '',   -- 新增：个性签名
    bio        VARCHAR(200),
    gender     SMALLINT     DEFAULT 0,
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
```

### 1.2 重置数据库 `✅`

```bash
powershell -ExecutionPolicy Bypass -File scripts/server/reset_db.ps1
```

---

## 任务 2：flash-core 更新 — User + extract_user_id `✅ 已完成`

### 2.1 User 结构体新增 signature 字段 `✅`

文件：`server/modules/flash-core/src/state.rs`（修改）

```rust
#[derive(Clone, Serialize)]
pub struct User {
    pub user_id: i64,
    pub phone: String,
    pub nickname: String,
    pub avatar: String,
    pub signature: String,
}
```

### 2.2 extract_user_id 提取到 jwt.rs `✅`

文件：`server/modules/flash-core/src/jwt.rs`（修改）

```rust
pub fn extract_user_id(headers: &HeaderMap) -> Result<i64, StatusCode> {
    let token = headers
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or(StatusCode::UNAUTHORIZED)?;
    verify_token(token).map_err(|_| StatusCode::UNAUTHORIZED)
}
```

### 2.3 Cargo.toml 确认依赖 `✅`

文件：`server/modules/flash-core/Cargo.toml`（确认）

flash-core 已有 `axum.workspace = true`，无需新增依赖。

---

## 任务 3：flash-user crate — 项目骨架 `✅ 已完成`

### 3.1 创建 Cargo.toml `✅`

文件：`server/modules/flash-user/Cargo.toml`（新建）

```toml
[package]
name = "flash-user"
version = "0.1.0"
edition = "2024"

[dependencies]
flash-core = { path = "../flash-core" }
axum.workspace = true
tokio.workspace = true
serde.workspace = true
sqlx.workspace = true
argon2 = "0.5"
```

### 3.2 创建目录结构 `✅`

```
server/modules/flash-user/
├── Cargo.toml
└── src/
    ├── lib.rs
    ├── routes.rs
    ├── handler.rs
    └── model.rs
```

---

## 任务 4：flash-user model.rs — 请求/响应结构体 `✅ 已完成`

文件：`server/modules/flash-user/src/model.rs`（新建）

### 4.1 UpdateProfileRequest `✅`

```rust
#[derive(Deserialize)]
pub struct UpdateProfileRequest {
    pub nickname: Option<String>,
    pub avatar: Option<String>,
    pub signature: Option<String>,
}
```

### 4.2 SetPasswordRequest `✅`

```rust
#[derive(Deserialize)]
pub struct SetPasswordRequest {
    pub new_password: String,
}
```

### 4.3 ChangePasswordRequest `✅`

```rust
#[derive(Deserialize)]
pub struct ChangePasswordRequest {
    pub old_password: String,
    pub new_password: String,
}
```

### 4.4 MessageResponse `✅`

```rust
#[derive(Serialize)]
pub struct MessageResponse {
    pub message: String,
}
```

---

## 任务 5：flash-user handler.rs — 四个接口实现 `✅ 已完成`

文件：`server/modules/flash-user/src/handler.rs`（新建）

### 5.1 profile — GET /user/profile `✅`

```rust
pub async fn profile(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
) -> Result<Json<User>, StatusCode>
```

### 5.2 update_profile — PUT /user/profile `✅`

```rust
pub async fn update_profile(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<UpdateProfileRequest>,
) -> Result<Json<User>, StatusCode>
```

动态构建 UPDATE SQL，只更新传入的 Option::Some 字段。

### 5.3 set_password — POST /user/password `✅`

```rust
pub async fn set_password(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<SetPasswordRequest>,
) -> Result<Json<MessageResponse>, StatusCode>
```

新增 409 冲突检查：已有密码则拒绝。

### 5.4 change_password — PUT /user/password `✅`

```rust
pub async fn change_password(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<ChangePasswordRequest>,
) -> Result<Json<MessageResponse>, StatusCode>
```

验证旧密码后才允许修改。

### 5.5 find_user_by_id 辅助函数 `✅`

SQL 查询包含 signature 字段：

```sql
SELECT p.account_id, p.nickname, p.avatar, p.signature
FROM user_profiles p
JOIN accounts a ON a.id = p.account_id
WHERE p.account_id = $1 AND a.status = 0
```

---

## 任务 6：flash-user routes.rs + lib.rs — 路由与公开 API `✅ 已完成`

### 6.1 routes.rs `✅`

文件：`server/modules/flash-user/src/routes.rs`（新建）

```rust
pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/user/profile", get(profile).put(update_profile))
        .route("/user/password", post(set_password).put(change_password))
}
```

### 6.2 lib.rs `✅`

文件：`server/modules/flash-user/src/lib.rs`（新建）

```rust
pub fn router() -> Router<Arc<AppState>> {
    routes::router()
}
```

---

## 任务 7：flash-auth 清理 — 删除迁出的代码 `✅ 已完成`

### 7.1 handler.rs — 删除 set_password 和 extract_user_id `✅`

文件：`server/modules/flash-auth/src/handler.rs`（修改）

删除 `set_password`、`extract_user_id`，清理不再需要的 import（`PasswordHasher`、`SaltString`、`HeaderMap`、`verify_token`）。

### 7.2 routes.rs — 删除 /auth/password 路由 `✅`

文件：`server/modules/flash-auth/src/routes.rs`（修改）

只保留 `/auth/sms` 和 `/auth/login`。

### 7.3 model.rs — 删除 PasswordRequest + MessageResponse `✅`

文件：`server/modules/flash-auth/src/model.rs`（修改）

---

## 任务 8：flash-auth 默认头像 — identicon 标记 `✅ 已完成`

文件：`server/modules/flash-auth/src/handler.rs`（修改）

### 8.1 修改 find_or_create_user 中的默认头像 `✅`

```rust
let avatar = format!("identicon:{}", account_id);
```

---

## 任务 9：workspace 配置 — Cargo.toml 更新 `✅ 已完成`

文件：`server/Cargo.toml`（修改）

### 9.1 workspace members 新增 `✅`

```toml
members = [
    ".",
    "modules/flash-core",
    "modules/flash-auth",
    "modules/flash-user",
]
```

### 9.2 主 binary 新增依赖 `✅`

```toml
flash-user = { path = "modules/flash-user" }
```

---

## 任务 10：main.rs 更新 — 集成 flash-user `✅ 已完成`

文件：`server/src/main.rs`（修改）

### 10.1 删除 mod user `✅`

### 10.2 替换路由 `✅`

```rust
.merge(flash_user::router())
```

### 10.3 删除旧文件 `✅`

删除 `server/src/user/`（handler.rs, routes.rs, mod.rs）

---

## 任务 11：编译验证 + 测试路径 `✅ 已完成`

### 11.1 cargo build `✅`

零错误零警告通过。

### 11.2 启动服务 `✅`

`powershell -ExecutionPolicy Bypass -File scripts/server/start.ps1` 正常启动。

### 11.3 测试链验证 `✅`

通过 `docs/features/session/api/request/user_profile.ps1` 全部 8 步测试通过：

1. GET /user/profile — 200，包含 signature 字段，默认头像 identicon 格式
2. PUT /user/profile — 200，修改昵称/签名成功
3. PUT /user/profile — 200，更换 identicon 头像
4. POST /user/password — 200，首次设置密码
5. POST /user/password — 409，重复设置拒绝
6. PUT /user/password — 200，修改密码成功
7. PUT /user/password — 401，旧密码错误拒绝
8. POST /auth/login — 200，新密码登录成功
