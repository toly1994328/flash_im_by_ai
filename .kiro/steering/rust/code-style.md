---
inclusion: fileMatch
fileMatchPattern: "**/*.rs"
---

# Rust 后端代码风格

## 分层职责

- **routes 层**：解析参数 + 调用 service + 构造响应。禁止直接写 SQL。
- **service 层**：业务逻辑、权限校验、事务编排。
- **repository 层**：纯数据访问，一个方法一条 SQL。

## 公共工具

- 查用户昵称：`flash_core::get_nickname(db, user_id).await`，不要重复写 SQL。
- 新的跨模块工具方法放 `flash-core`，不要在业务模块里重复实现。

## 代码风格

- 范围限制用 `.clamp(min, max)`，不用 `.min(x).max(y)`。
- 嵌套 if 能合并就合并：`if let Ok(v) = expr && condition { ... }`。
- 查询结果超过 3 个字段时定义结构体（`#[derive(FromRow)]`），不用元组。
- 有 `new()` 的类型加 `impl Default`。
- 不用的 import 及时删除。
