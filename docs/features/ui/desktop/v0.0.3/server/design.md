# 后端设计 — Web 加载优化

## 变更范围

仅涉及 `server/` 根 crate，不涉及任何子模块。

## 依赖变更

```toml
# server/Cargo.toml
tower-http = { version = "0.6", features = ["fs", "compression-gzip", "compression-br", "set-header"] }
```

新增 features：`compression-gzip`、`compression-br`、`set-header`

## 中间件配置

在 `src/main.rs` 的 Router 上追加三个 layer：

### 1. Gzip/Brotli 压缩

```rust
.layer(CompressionLayer::new())
```

自动根据请求的 `Accept-Encoding` 选择 Gzip 或 Brotli 压缩响应体。对 JS/Wasm 文件压缩率约 70%。

### 2. Cross-Origin-Embedder-Policy

```rust
.layer(SetResponseHeaderLayer::overriding(
    HeaderName::from_static("cross-origin-embedder-policy"),
    HeaderValue::from_static("credentialless"),
))
```

告知浏览器"不会加载带凭证的跨域资源"，配合 COOP 解锁 SharedArrayBuffer。

### 3. Cross-Origin-Opener-Policy

```rust
.layer(SetResponseHeaderLayer::overriding(
    HeaderName::from_static("cross-origin-opener-policy"),
    HeaderValue::from_static("same-origin"),
))
```

进程隔离，配合 COEP 启用 WASM 多线程渲染（skwasm）。

## 静态文件路由变更

```rust
// 旧
.nest_service("/im", ServeDir::new("static/web").fallback(...))

// 新
.nest_service("/im", ServeDir::new("static/im").fallback(ServeFile::new("static/im/index.html")))
```

目录从 `static/web` 改为 `static/im`，路径更语义化。

## 版本号

`0.1.5` → `0.1.6`
