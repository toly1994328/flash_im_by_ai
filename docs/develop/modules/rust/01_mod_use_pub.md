# Rust 模块化基础：mod、use、pub

Rust 的模块系统核心就三个关键字：`mod` 声明模块，`use` 引入路径，`pub` 控制可见性。以 Flash IM 后端重构后的结构为例：

```
server/src/
├── main.rs
├── state.rs
├── auth/
│   ├── mod.rs
│   ├── handler.rs
│   ├── jwt.rs
│   ├── model.rs
│   └── routes.rs
├── ws/
│   ├── mod.rs
│   ├── auth.rs
│   ├── chat_room.rs
│   ├── handler.rs
│   └── routes.rs
├── mock/
│   ├── mod.rs
│   ├── handler.rs
│   └── routes.rs
└── util/
    ├── mod.rs
    └── network.rs
```

---

## 一、mod — 声明"我有哪些子模块"

`mod` 的作用是告诉 Rust 编译器："这里有一个模块，去对应的文件里找它的内容。"

### 文件模块

在 `main.rs` 里写 `mod state;`，Rust 会自动去找 `src/state.rs`：

```rust
// main.rs
mod state;    // → 编译器去找 src/state.rs
mod auth;     // → 编译器去找 src/auth/mod.rs（目录模块）
mod ws;       // → 编译器去找 src/ws/mod.rs
mod mock;     // → 编译器去找 src/mock/mod.rs
mod util;     // → 编译器去找 src/util/mod.rs
```

规则很简单：
- `mod xxx;` → 找 `src/xxx.rs`（文件模块）
- `mod xxx;` → 或找 `src/xxx/mod.rs`（目录模块）

两者二选一，不能同时存在。当一个模块下面还有子模块时，用目录形式。

### 目录模块的入口：mod.rs

`auth/mod.rs` 的职责是声明 `auth` 目录下有哪些子模块：

```rust
// auth/mod.rs
pub mod handler;   // → 找 auth/handler.rs
pub mod jwt;       // → 找 auth/jwt.rs
pub mod model;     // → 找 auth/model.rs
pub mod routes;    // → 找 auth/routes.rs
```

这里的 `pub` 表示子模块对外可见。如果不加 `pub`，这些子模块只有 `auth` 内部能访问。

### 模块树

所有的 `mod` 声明串起来，形成一棵模块树：

```
crate（根，即 main.rs）
├── state
├── auth
│   ├── handler
│   ├── jwt
│   ├── model
│   └── routes
├── ws
│   ├── auth
│   ├── chat_room
│   ├── handler
│   └── routes
├── mock
│   ├── handler
│   └── routes
└── util
    └── network
```

这棵树决定了所有路径的起点。

---

## 二、use — 声明"我要用别人的什么东西"

`use` 把其他模块的内容引入当前作用域，避免每次都写完整路径。

### 三种路径前缀

```rust
// 1. crate:: — 从项目根开始（绝对路径）
use crate::state::AppState;
use crate::state::User;
use crate::auth::jwt::verify_token;

// 2. super:: — 从父模块开始（相对路径）
// 比如在 auth/handler.rs 里，想用同级的 jwt.rs：
use super::jwt::generate_token;    // super = auth/
use super::model::LoginRequest;    // super = auth/

// 3. 外部依赖 — 直接写 crate 名
use axum::Router;
use serde::Serialize;
use tokio::sync::Mutex;
```

### 什么时候用 crate::，什么时候用 super::

- 跨模块引用（比如 `ws` 模块要用 `auth` 模块的东西）→ 用 `crate::`
- 同模块内部引用（比如 `auth/handler.rs` 要用 `auth/jwt.rs`）→ 用 `super::`

实际例子：

```rust
// ws/auth.rs — 需要用 auth 模块的 JWT 验证（跨模块）
use crate::auth::jwt::verify_token;
use crate::state::{AppState, User};

// auth/handler.rs — 需要用同模块的 jwt 和 model（同模块）
use super::jwt::generate_token;
use super::model::{LoginRequest, LoginResponse, SmsRequest, SmsResponse};
```

### 批量引入

用花括号一次引入多个：

```rust
use crate::state::{AppState, User};           // 从同一个模块引入两个
use axum::{Router, extract::State, Json};      // 嵌套路径也可以
```

---

## 三、pub — 决定"我愿意让别人用什么"

`pub` 是模块的"细胞膜"——它控制哪些内容对外可见，哪些是内部私有的。

### 默认私有

Rust 中所有内容默认是私有的。不加 `pub`，只有当前模块内部能访问：

```rust
// state.rs
pub struct User {          // pub → 其他模块能用这个结构体
    pub user_id: i64,      // pub → 字段也对外可见
    pub phone: String,
    pub nickname: String,
    pub avatar: String,
}

pub fn create_app_state() -> Arc<AppState> {  // pub → 其他模块能调用
    // ...
}

fn internal_helper() {     // 没有 pub → 只有 state.rs 内部能用
    // ...
}
```

### pub 的层级

`pub` 需要逐层打开。即使函数是 `pub` 的，如果它所在的模块没有被 `pub mod` 声明，外部依然看不到：

```rust
// auth/mod.rs
pub mod jwt;        // ✅ jwt 模块对外可见
mod internal;       // ❌ internal 模块只有 auth 内部能用

// auth/jwt.rs
pub fn verify_token() { }   // ✅ 外部可以通过 crate::auth::jwt::verify_token 访问
fn helper() { }              // ❌ 只有 jwt.rs 内部能用
```

要让外部能访问 `verify_token`，需要满足两个条件：
1. `auth/mod.rs` 里用 `pub mod jwt;` 声明
2. `jwt.rs` 里用 `pub fn verify_token()` 声明

两层"门"都要打开，外部才能进来。

---

## 四、实际路径追踪

以 `ws/chat_room.rs` 引用 `wait_for_auth` 为例，追踪完整的路径：

```rust
// ws/chat_room.rs
use super::auth::wait_for_auth;
```

路径解析过程：
1. `super` → 父模块 `ws`
2. `auth` → `ws/auth.rs`（因为 `ws/mod.rs` 里声明了 `pub mod auth;`）
3. `wait_for_auth` → `ws/auth.rs` 里的 `pub async fn wait_for_auth()`

再看一个跨模块的例子：

```rust
// ws/auth.rs
use crate::auth::jwt::verify_token;
```

路径解析过程：
1. `crate` → 项目根 `main.rs`
2. `auth` → `src/auth/mod.rs`（因为 `main.rs` 里声明了 `mod auth;`）
3. `jwt` → `auth/jwt.rs`（因为 `auth/mod.rs` 里声明了 `pub mod jwt;`）
4. `verify_token` → `auth/jwt.rs` 里的 `pub fn verify_token()`

---

## 五、一句话总结

| 关键字 | 作用 | 类比 |
|--------|------|------|
| `mod` | 声明"我有哪些子模块" | 器官声明自己包含哪些组织 |
| `use` | 引入"我要用别人的什么" | 血管连接不同器官 |
| `pub` | 控制"我愿意暴露什么" | 细胞膜决定什么能进出 |

三者配合：`mod` 构建模块树，`pub` 在树上开门，`use` 沿着树走路。
