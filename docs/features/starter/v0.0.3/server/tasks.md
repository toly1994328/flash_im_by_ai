# app-center — 后端任务清单

基于 server/design.md 设计，列出需要创建/修改的具体细节。
全局约束：错误处理使用 AppError，handler 返回 Result<Json<...>, AppError>。

---

## 执行顺序

1. ✅ 任务 1 — Cargo.toml 配置
2. ✅ 任务 2 — 数据库迁移脚本
3. ✅ 任务 3 — models.rs 数据结构
4. ✅ 任务 4 — routes.rs 路由处理
5. ✅ 任务 5 — lib.rs 模块入口
6. ✅ 任务 6 — main.rs 注册路由
7. ✅ 任务 7 — 编译验证 + 测试

---

## 任务 1：Cargo.toml 配置 `✅ 已完成`

### 1.1 新建 app-center 模块 `✅`

文件：`server/modules/app-center/Cargo.toml`

```toml
[package]
name = "app-center"
version = "0.1.0"
edition = "2024"

[dependencies]
axum.workspace = true
serde.workspace = true
serde_json.workspace = true
sqlx.workspace = true
```

### 1.2 注册到 workspace `✅`

`server/Cargo.toml` 的 `[workspace] members` 中已添加 `"modules/app-center"`，
根 crate 的 `[dependencies]` 中已添加 `app-center = { path = "modules/app-center" }`。

---

## 任务 2：数据库迁移脚本 `✅ 已完成`

建表 SQL 已执行：

```sql
CREATE TABLE IF NOT EXISTS apps (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_versions (
    id SERIAL PRIMARY KEY,
    app_id VARCHAR(64) NOT NULL REFERENCES apps(id),
    platform VARCHAR(32) NOT NULL,
    version VARCHAR(32) NOT NULL,
    download_url VARCHAR(512) NOT NULL,
    file_size BIGINT NOT NULL DEFAULT 0,
    sha256 VARCHAR(64),
    release_notes TEXT,
    force_update BOOLEAN NOT NULL DEFAULT FALSE,
    published BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(app_id, platform, version)
);

CREATE INDEX IF NOT EXISTS idx_app_versions_lookup
    ON app_versions(app_id, platform, created_at DESC);
```

---

## 任务 3：models.rs 数据结构 `✅ 已完成`

文件：`server/modules/app-center/src/models.rs`

| 结构体 | 用途 |
|--------|------|
| `AppVersionRow` | GET 查询返回给客户端 |
| `VersionQuery` | GET 查询参数 (app_id, platform) |
| `CreateVersionPayload` | POST 新增版本请求体 |
| `UpdateVersionQuery` | PUT 更新查询参数 (app_id, platform, version) |
| `UpdateVersionPayload` | PUT 更新请求体（所有字段可选） |
| `AppRow` | 应用列表返回 |
| `CreateAppPayload` | 新增应用请求体 |
| `AppIdQuery` | 按 app_id 查询参数 |
| `AppVersionFullRow` | 版本列表完整行（含 published、id、created_at） |
| `PublishQuery` | 发布/撤回/删除查询参数 |

---

## 任务 4：routes.rs 路由处理 `✅ 已完成`

文件：`server/modules/app-center/src/routes.rs`

### 已实现接口

| 方法 | 路径 | Handler | 说明 |
|------|------|---------|------|
| GET | /api/app/version | `get_version` | 查询最新已发布版本（published=true） |
| POST | /api/app/version | `create_version` | 新增版本记录 |
| PUT | /api/app/version | `update_version` | 更新已有版本信息（动态 SET 构建） |
| DELETE | /api/app/version | `delete_version` | 删除版本记录 |
| POST | /api/app/version/publish | `publish_version` | 设 published=true |
| POST | /api/app/version/unpublish | `unpublish_version` | 设 published=false |
| GET | /api/app/list | `list_apps` | 获取所有应用 |
| POST | /api/app | `create_app` | 新增应用 |
| GET | /api/app/versions | `list_versions` | 获取某应用的全部版本记录 |

### 关键设计点

1. `get_version` 只返回 `published = true` 的版本，避免商店审核未通过时客户端已提示更新
2. `update_version` 动态构建 SET 子句，只更新非 None 字段
3. `create_version` 的 UNIQUE 冲突返回 400（版本已存在）
4. 所有 handler 返回 `Result<..., AppError>`，错误通过 `?` 传播

---

## 任务 5：lib.rs 模块入口 `✅ 已完成`

文件：`server/modules/app-center/src/lib.rs`

```rust
pub fn router(db: PgPool) -> Router {
    Router::new()
        .route("/api/app/list", get(routes::list_apps))
        .route("/api/app", post(routes::create_app))
        .route("/api/app/versions", get(routes::list_versions))
        .route("/api/app/version", get(routes::get_version))
        .route("/api/app/version", post(routes::create_version))
        .route("/api/app/version", put(routes::update_version))
        .route("/api/app/version", delete(routes::delete_version))
        .route("/api/app/version/publish", post(routes::publish_version))
        .route("/api/app/version/unpublish", post(routes::unpublish_version))
        .with_state(db)
}
```

---

## 任务 6：main.rs 注册路由 `✅ 已完成`

`server/src/main.rs` 中已添加：

```rust
.merge(app_center::router(db.clone()))
```

---

## 任务 7：编译验证 + 测试 `✅ 已完成`

### 7.1 编译 `✅`

`cargo build` 通过。

### 7.2 接口验证 `✅`

API 测试脚本：`docs/features/starter/v0.0.3/api/app-center/request/app_center.py`
API 测试记录：`docs/features/starter/v0.0.3/api/app-center/doc/` 目录下 18 个测试用例文档。

已验证场景：
- 创建应用、重复创建返回错误
- 创建版本、重复版本号返回错误
- 查询最新版本（仅返回 published=true）
- 查询不存在的版本返回 404
- 更新版本字段
- 发布/撤回版本
- 删除版本

---

## 发布流程

构建产物发布到后端的完整流程：

```bash
# 1. 构建 APK
python scripts/build_center/build_android.py

# 2. 查看生成的 meta.json（自动计算 sha256 + file_size）
cat scripts/build_center/dest/android/arm64-v8a/meta.json

# 3. 上传 APK 到文件服务器（手动或脚本）

# 4. 调接口创建版本记录
curl -X POST http://127.0.0.1:9600/api/app/version \
  -H "Content-Type: application/json" \
  -d '{
    "app_id": "flash_im",
    "platform": "android",
    "version": "0.0.2",
    "download_url": "https://your-server/releases/flash_im_0.0.2.apk",
    "file_size": 25000000,
    "sha256": "从 meta.json 中获取",
    "release_notes": "修复已知问题",
    "force_update": false
  }'

# 5. 发布（客户端才能查到）
curl -X POST "http://127.0.0.1:9600/api/app/version/publish?app_id=flash_im&platform=android&version=0.0.2"
```

客户端在启动时调用 `GET /api/app/version?app_id=flash_im&platform=android`，
收到响应后比较版本号，有更新则弹窗，下载后用 `meta.json` 中的 SHA256 校验完整性。
