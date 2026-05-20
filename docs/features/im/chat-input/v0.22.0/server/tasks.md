# 聊天输入框优�?�?服务端任务清�?

基于 design.md 设计，列出需要创�?修改的具体细节�?

全局约束�?
- 遵循 Rust 错误处理规范（`.kiro/steering/rust/error-handling.md`�?
- proto 编译�?`build.rs` 自动完成，只需修改 `.proto` 文件�?`cargo build`

---

## 执行顺序

1. �?任务 1 �?Proto 新增 AUDIO 类型
2. �?任务 2 �?generate_preview 新增语音预览
3. �?任务 3 �?编译验证

---

## 任务 1：message.proto �?新增 AUDIO 类型 `�?已完成`

文件：`server/modules/im-ws/proto/message.proto`

### 1.1 MessageType 枚举新增 AUDIO `⬜`

```protobuf
enum MessageType {
  TEXT = 0;
  IMAGE = 1;
  VIDEO = 2;
  FILE = 3;
  AUDIO = 4;    // �?新增
  FORWARD = 5;
}
```

---

## 任务 2：models.rs �?generate_preview 新增语音 `�?已完成`

文件：`server/modules/im-message/src/models.rs`

### 2.1 新增 match 分支 `⬜`

```rust
pub fn generate_preview(content: &str, msg_type: i16) -> String {
    match msg_type {
        1 => "[图片]".to_string(),
        2 => "[视频]".to_string(),
        3 => "[文件]".to_string(),
        4 => "[语音]".to_string(),  // �?新增
        _ => { ... }
    }
}
```

---

## 任务 3：编译验�?`�?已完成`

### 3.1 cargo build `⬜`

```bash
cd server && cargo build
```

期望：编译通过，proto 自动重新生成�?

### 3.2 cargo clippy `⬜`

```bash
cd server && cargo clippy --workspace -- -W clippy::all
```

期望：无新增 warning�?
