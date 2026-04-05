# IM Core v0.0.4_media — 服务端任务清单

基于 [design.md](./design.md) 设计，列出需要创建/修改的具体细节。

全局约束：
- 错误处理：app-storage 使用 thiserror 枚举，im-message / im-ws 沿用现有 StatusCode 模式
- app-storage 不依赖任何 IM 业务 crate
- 不实现上传鉴权、语音消息、云存储、断点续传

---

## 执行顺序

1. ✅ 任务 1 — proto 扩展 MessageType 枚举（无依赖）
2. ✅ 任务 2 — app-storage crate 骨架 + Cargo.toml（无依赖）
   - ✅ 2.1 Cargo.toml
   - ✅ 2.2 StorageError + StorageConfig + UploadResult 类型定义
   - ✅ 2.3 ImageProcessor 图片处理
   - ✅ 2.4 StorageService 核心逻辑
   - ✅ 2.5 API 路由
   - ✅ 2.6 lib.rs 模块入口
3. ✅ 任务 3 — workspace 配置（依赖任务 2）
   - ✅ 3.1 server/Cargo.toml workspace members
   - ✅ 3.2 server/Cargo.toml 根 package 依赖
4. ✅ 任务 4 — im-message 模型扩展（依赖任务 1）
   - ✅ 4.1 NewMessage 增加字段
   - ✅ 4.2 新增 generate_preview 函数
5. ✅ 任务 5 — im-message repository 扩展（依赖任务 4）
6. ✅ 任务 6 — im-message service 扩展（依赖任务 4、5）
7. ✅ 任务 7 — im-ws dispatcher 扩展（依赖任务 4）
8. ✅ 任务 8 — im-ws broadcaster 扩展（无新依赖）
9. ✅ 任务 9 — main.rs 集成（依赖任务 2、3）
10. ✅ 任务 10 — 编译验证 + 测试路径

---

## 任务 1：message.proto — MessageType 枚举扩展 `✅ 已完成`

文件：`proto/message.proto`（修改）

### 1.1 新增枚举值 `✅`

在 MessageType 枚举中新增三个值：

```protobuf
enum MessageType {
  TEXT = 0;
  IMAGE = 1;
  VIDEO = 2;
  FILE = 3;
}
```

proto 修改后 im-ws 的 build.rs 会在下次 cargo build 时自动重新生成 Rust 代码。

---

## 任务 2：app-storage crate — 文件存储模块 `⬜ 待处理`

### 2.1 Cargo.toml `⬜`

文件：`server/modules/app-storage/Cargo.toml`（新建）

```toml
[package]
name = "app-storage"
version = "0.1.0"
edition = "2024"

[dependencies]
axum.workspace = true
tokio.workspace = true
serde.workspace = true
serde_json.workspace = true
chrono.workspace = true
uuid = { version = "1", features = ["v4"] }
image = "0.25"
thiserror = "2"
```

### 2.2 类型定义 `⬜`

文件：`server/modules/app-storage/src/service.rs`（新建）

定义以下类型：

```rust
/// StorageError — thiserror 枚举
pub enum StorageError {
    NotFound(String),
    UnsupportedType(String),
    FileTooLarge { size: u64, max: u64 },
    Io(#[from] std::io::Error),
    Image(#[from] crate::image::ImageError),
}

/// StorageConfig
pub struct StorageConfig {
    pub base_path: PathBuf,       // 默认 "uploads"
    pub url_prefix: String,       // 默认 "/uploads"
    pub max_image_size: u64,      // 默认 10MB
    pub max_video_size: u64,      // 默认 50MB
    pub max_file_size: u64,       // 默认 50MB
    pub thumbnail_max_size: u32,  // 默认 200
    pub thumbnail_quality: u8,    // 默认 80
}

/// UploadResult（图片上传返回）
pub struct UploadResult {
    pub original_url: String,
    pub thumbnail_url: Option<String>,
    pub width: Option<u32>,
    pub height: Option<u32>,
    pub size: u64,
    pub format: String,
}

/// VideoUploadMetadata（前端提供的视频元数据）
pub struct VideoUploadMetadata {
    pub duration_ms: u64,
    pub width: u32,
    pub height: u32,
}

/// VideoUploadResult
pub struct VideoUploadResult {
    pub video_url: String,
    pub thumbnail_url: String,
    pub duration_ms: u64,
    pub width: u32,
    pub height: u32,
    pub file_size: u64,
}

/// FileUploadResult
pub struct FileUploadResult {
    pub file_url: String,
    pub file_name: String,
    pub file_size: u64,
    pub file_type: String,
}
```

为 StorageConfig 实现 Default trait。新增 `StorageConfig::from_env()` 方法，从环境变量读取配置，缺失时使用默认值：

| 环境变量 | 说明 | 默认值 |
|---------|------|--------|
| UPLOAD_BASE_PATH | 存储根目录 | `uploads` |
| UPLOAD_MAX_IMAGE_SIZE | 图片最大字节数 | `10485760`（10MB） |
| UPLOAD_MAX_VIDEO_SIZE | 视频最大字节数 | `52428800`（50MB） |
| UPLOAD_MAX_FILE_SIZE | 文件最大字节数 | `52428800`（50MB） |

### 2.3 ImageProcessor `⬜`

文件：`server/modules/app-storage/src/image.rs`（新建）

```rust
pub enum ImageError {
    Decode(String),
    Encode(String),
    UnsupportedFormat,
}

#[derive(Clone)]
pub struct ImageProcessor {
    max_size: u32,
    quality: u8,
}
```

方法：

- `pub fn new(max_size: u32, quality: u8) -> Self`
- `pub fn process(&self, data: &[u8]) -> Result<(u32, u32, Vec<u8>), ImageError>`
  1. 用 `image::ImageReader` 解码图片，获取 width/height
  2. 调用 `generate_thumbnail()` 缩放到 max_size
  3. 调用 `encode_webp()` 编码为 webp
  4. 返回 (width, height, thumb_data)
- `fn generate_thumbnail(&self, img: &DynamicImage) -> DynamicImage`
  1. 如果宽高都 ≤ max_size，直接返回
  2. 否则按长边缩放，保持宽高比，用 Lanczos3 滤波
- `fn encode_webp(&self, img: &DynamicImage) -> Result<Vec<u8>, ImageError>`
  1. 用 `img.write_to(&mut buf, ImageFormat::WebP)` 编码

### 2.4 StorageService `⬜`

文件：`server/modules/app-storage/src/service.rs`（续）

```rust
#[derive(Clone)]
pub struct StorageService {
    config: StorageConfig,
    image_processor: ImageProcessor,
}
```

方法：

- `pub fn new(config: StorageConfig) -> Self`
  1. 用 config 的 thumbnail 参数创建 ImageProcessor
- `pub fn max_video_size(&self) -> u64`
- `pub fn max_file_size(&self) -> u64`
- `pub async fn upload_image(&self, data: &[u8], filename: &str) -> Result<UploadResult, StorageError>`
  1. 检查 data.len() ≤ max_image_size
  2. 从 filename 提取扩展名，校验白名单 (jpg/jpeg/png/gif/webp)
  3. 生成路径：`{base_path}/original/{yyyy}/{mm}/{uuid}.{ext}`
  4. `tokio::fs::create_dir_all` + `tokio::fs::write` 写入原图
  5. `image_processor.process(data)` 获取 (width, height, thumb_data)
  6. 写入缩略图：`{base_path}/thumb/{yyyy}/{mm}/{uuid}.webp`
  7. 拼接 URL 返回
- `pub async fn upload_video(&self, video_data: &[u8], video_filename: &str, thumb_data: &[u8], metadata: VideoUploadMetadata) -> Result<VideoUploadResult, StorageError>`
  1. 检查 video_data.len() ≤ max_video_size
  2. 校验扩展名白名单 (mp4/mov/avi)
  3. 写入视频：`{base_path}/video/{yyyy}/{mm}/{uuid}.{ext}`
  4. 写入缩略图：`{base_path}/thumb/{yyyy}/{mm}/{uuid}.jpg`
  5. 拼接 URL 返回
- `pub async fn upload_file(&self, data: &[u8], filename: &str) -> Result<FileUploadResult, StorageError>`
  1. 检查 data.len() ≤ max_file_size
  2. 从 filename 提取扩展名（无白名单限制）
  3. 写入：`{base_path}/file/{yyyy}/{mm}/{uuid}.{ext}`
  4. 拼接 URL 返回

### 2.5 API 路由 `⬜`

文件：`server/modules/app-storage/src/api.rs`（新建）

响应结构体（均 derive Serialize）：

```rust
pub struct ImageUploadResponse {
    pub original_url: String,
    pub thumbnail_url: String,
    pub width: u32,
    pub height: u32,
    pub size: u64,
    pub format: String,
}

pub struct VideoUploadResponse {
    pub video_url: String,
    pub thumbnail_url: String,
    pub duration_ms: u64,
    pub width: u32,
    pub height: u32,
    pub file_size: u64,
}

pub struct FileUploadResponse {
    pub file_url: String,
    pub file_name: String,
    pub file_size: u64,
    pub file_type: String,
}
```

路由处理函数：

- `async fn upload_image(State(storage): State<Arc<StorageService>>, mut multipart: Multipart) -> Result<Json<ImageUploadResponse>, StatusCode>`
  1. `multipart.next_field()` 取文件
  2. 提取 filename、读取 bytes
  3. 调用 `storage.upload_image()`
  4. 转换为 ImageUploadResponse 返回
  5. 错误统一映射为 StatusCode::BAD_REQUEST 或 INTERNAL_SERVER_ERROR

- `async fn upload_video(State(storage): State<Arc<StorageService>>, mut multipart: Multipart) -> Result<Json<VideoUploadResponse>, StatusCode>`
  1. 循环 `multipart.next_field()` 解析 video / thumbnail / duration_ms / width / height
  2. 校验必填字段（video、thumbnail、duration_ms）
  3. 调用 `storage.upload_video()`
  4. 返回 VideoUploadResponse

- `async fn upload_file(State(storage): State<Arc<StorageService>>, mut multipart: Multipart) -> Result<Json<FileUploadResponse>, StatusCode>`
  1. `multipart.next_field()` 取文件
  2. 调用 `storage.upload_file()`
  3. 返回 FileUploadResponse

路由注册函数：

```rust
pub fn storage_routes(storage: Arc<StorageService>) -> Router {
    let video_limit = storage.max_video_size() as usize;
    let file_limit = storage.max_file_size() as usize;
    Router::new()
        .route("/api/upload/image", post(upload_image))
        .route("/api/upload/video", post(upload_video).layer(DefaultBodyLimit::max(video_limit)))
        .route("/api/upload/file", post(upload_file).layer(DefaultBodyLimit::max(file_limit)))
        .with_state(storage)
}
```

### 2.6 lib.rs `⬜`

文件：`server/modules/app-storage/src/lib.rs`（新建）

```rust
pub mod api;
pub mod image;
pub mod service;

pub use service::{StorageService, StorageConfig};
```

---

## 任务 3：workspace 配置 `⬜ 待处理`

### 3.1 workspace members `⬜`

文件：`server/Cargo.toml`（修改）

在 `[workspace] members` 数组中新增：

```toml
"modules/app-storage",
```

### 3.2 根 package 依赖 `⬜`

文件：`server/Cargo.toml`（修改）

在 `[dependencies]` 中新增：

```toml
app-storage = { path = "modules/app-storage" }
```

---

## 任务 4：im-message models.rs — NewMessage 扩展 + generate_preview `⬜ 待处理`

文件：`server/modules/im-message/src/models.rs`（修改）

### 4.1 NewMessage 增加字段 `⬜`

当前 NewMessage：

```rust
pub struct NewMessage {
    pub conversation_id: Uuid,
    pub sender_id: i64,
    pub content: String,
}
```

改为：

```rust
pub struct NewMessage {
    pub conversation_id: Uuid,
    pub sender_id: i64,
    pub content: String,
    pub msg_type: i16,                        // 新增，默认 0
    pub extra: Option<serde_json::Value>,     // 新增
}
```

### 4.2 新增 generate_preview 函数 `⬜`

在 models.rs 中新增公开函数：

```rust
/// 根据消息类型生成会话预览文本
pub fn generate_preview(content: &str, msg_type: i16) -> String
```

逻辑：
1. msg_type == 1 → 返回 `"[图片]"`
2. msg_type == 2 → 返回 `"[视频]"`
3. msg_type == 3 → 返回 `"[文件]"`
4. 其他 → 文本截断前 50 字符，超出加 `"..."`

---

## 任务 5：im-message repository.rs — create SQL 扩展 `⬜ 待处理`

文件：`server/modules/im-message/src/repository.rs`（修改）

### 5.1 create() 写入 type 和 extra `⬜`

当前 SQL：

```sql
INSERT INTO messages (conversation_id, sender_id, seq, content)
VALUES ($1, $2, $3, $4) RETURNING *
```

改为：

```sql
INSERT INTO messages (conversation_id, sender_id, seq, type, content, extra)
VALUES ($1, $2, $3, $4, $5, $6) RETURNING *
```

对应 bind 参数增加 `msg.msg_type` 和 `&msg.extra`。

查询方法（find_before_with_sender / find_latest_with_sender）无需改动，已经在 SELECT 中包含 msg_type 和 extra 字段。

---

## 任务 6：im-message service.rs — 预览生成逻辑 `⬜ 待处理`

文件：`server/modules/im-message/src/service.rs`（修改）

### 6.1 send() 使用 generate_preview `⬜`

当前预览生成逻辑（在 send 方法中）：

```rust
let preview = if msg.content.chars().count() > 50 {
    format!("{}...", msg.content.chars().take(50).collect::<String>())
} else {
    msg.content.clone()
};
```

替换为：

```rust
let preview = crate::models::generate_preview(&msg.content, msg.msg_type);
```

### 6.2 send() 内容校验调整 `⬜`

当前校验：

```rust
if msg.content.trim().is_empty() {
    return Err(StatusCode::BAD_REQUEST);
}
```

富媒体消息的 content 是 URL，不会为空，此校验保留即可。但需确认：客户端发送图片/视频/文件消息时 content 不为空（是上传后的 URL）。无需改动。

---

## 任务 7：im-ws dispatcher.rs — 提取 type/extra `⬜ 待处理`

文件：`server/modules/im-ws/src/dispatcher.rs`（修改）

### 7.1 构造 NewMessage 时传递 type 和 extra `⬜`

当前代码：

```rust
let new_msg = NewMessage {
    conversation_id,
    sender_id,
    content: request.content,
};
```

改为：

```rust
let new_msg = NewMessage {
    conversation_id,
    sender_id,
    content: request.content,
    msg_type: request.r#type as i16,
    extra: if request.extra.is_empty() {
        None
    } else {
        serde_json::from_slice(&request.extra).ok()
    },
};
```

说明：
- `request.r#type` 是 proto 生成的 i32 枚举值，转为 i16 存入数据库
- `request.extra` 是 bytes 字段，客户端发送时用 JSON 编码，这里反序列化为 serde_json::Value
- 如果 extra 为空 bytes 或解析失败，设为 None

需要在文件顶部新增 import：`use serde_json;`（im-ws 的 Cargo.toml 需要确认是否已有 serde_json 依赖，当前没有，需要添加）。

### 7.2 im-ws Cargo.toml 新增 serde_json 依赖 `⬜`

文件：`server/modules/im-ws/Cargo.toml`（修改）

在 `[dependencies]` 中新增：

```toml
serde_json.workspace = true
```

---

## 任务 8：im-ws broadcaster.rs — 传递 extra 字段 `⬜ 待处理`

文件：`server/modules/im-ws/src/broadcaster.rs`（修改）

### 8.1 ChatMessage.extra 使用实际值 `⬜`

当前代码（broadcast_message 方法中）：

```rust
extra: vec![],
```

改为：

```rust
extra: message.extra
    .as_ref()
    .map(|v| serde_json::to_vec(v).unwrap_or_default())
    .unwrap_or_default(),
```

说明：将 `Option<serde_json::Value>` 序列化为 JSON bytes，与 proto 的 `bytes extra` 字段对应。如果 extra 为 None，保持空 vec。

---

## 任务 9：main.rs — 集成 storage 路由 + 静态文件服务 `⬜ 待处理`

文件：`server/src/main.rs`（修改）

### 9.1 创建 StorageService 并注册路由 `⬜`

在 main 函数中，`let app = Router::new()` 之前新增：

```rust
use app_storage::{StorageService, StorageConfig};
use app_storage::api::storage_routes;

let storage = Arc::new(StorageService::new(StorageConfig::from_env()));
```

在 Router 链中新增（在 `.nest_service("/static", ...)` 之前）：

```rust
.merge(storage_routes(storage))
.nest_service("/uploads", ServeDir::new("uploads"))
```

### 9.2 创建 uploads 目录 `⬜`

在项目根目录（server/ 同级或 server/ 内部，取决于 cargo run 的工作目录）创建 `uploads/.gitkeep`，确保目录存在。

StorageConfig 默认 base_path 为 `"uploads"`，是相对于 cargo run 工作目录的路径。由于 `start.ps1` 在 server/ 目录下执行 cargo run，所以实际路径是 `server/uploads/`。

---

## 任务 10：编译验证 + 测试路径 `⬜ 待处理`

### 10.1 编译验证 `⬜`

```bash
cd server
cargo build
```

预期：零 error。

### 10.2 手动测试路径 `⬜`

1. 启动服务：`powershell -ExecutionPolicy Bypass -File scripts/server/start.ps1`

2. 上传图片：
```bash
curl -F "file=@test.jpg" http://localhost:9600/api/upload/image
```
预期：返回 JSON 含 original_url、thumbnail_url、width、height

3. 访问上传的文件：
```bash
curl http://localhost:9600/uploads/original/2026/04/xxx.jpg -o /dev/null -w "%{http_code}"
```
预期：200

4. 上传视频：
```bash
curl -F "video=@test.mp4" -F "thumbnail=@thumb.jpg" -F "duration_ms=5000" http://localhost:9600/api/upload/video
```
预期：返回 JSON 含 video_url、thumbnail_url、duration_ms

5. 上传文件：
```bash
curl -F "file=@test.pdf" http://localhost:9600/api/upload/file
```
预期：返回 JSON 含 file_url、file_name、file_size

6. 通过 WS 发送图片消息（用现有 Python 测试脚本改造或手动构造）：
   - SendMessageRequest: type=IMAGE(1), content="/uploads/original/...", extra=空
   - 验证 MESSAGE_ACK 返回
   - 验证 conversations.last_message_preview = "[图片]"
   - 验证 messages 表 type=1
