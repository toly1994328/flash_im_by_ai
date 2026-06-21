# 云空间扩容 — OSS 存储 + iOS 内购（cloud/v0.0.3）

> 版本：v0.40.0  
> 状态：规划中  
> 分支：feature/v0.40.0

---

## 一、OSS 存储接入

### 设计原则

- 数据库 `storage_path` 继续存相对路径（`original/2026/06/xxx.jpg`），不动
- 消息内容也存相对路径，不动
- 前端已有逻辑：没有 `https://` 开头 → 拼 baseUrl；有 → 直接用。不动
- 只改后端：上传目标从本地磁盘换成 OSS，API 返回 URL 时 `url_prefix` 从 `/uploads` 变为 OSS 公网地址

### 上传架构（STS Token 直传）

```
前端 → POST /api/storage/upload-token → 后端签发 STS 临时凭证（限路径+时效15min）
前端 → PUT 文件直传阿里云 OSS（携带 STS Token）
前端 → POST /api/storage/confirm-upload → 后端记录元数据 + 扣减配额
```

优势：
- 文件不过服务器，省带宽和 CPU
- 临时凭证有时效（15min），泄露影响有限
- 可限制上传路径前缀（`users/{uid}/`）
- 支持大文件，不受服务端 body limit 限制

### 后端改动

| 文件 | 操作 | 内容 |
|------|------|------|
| `backend/oss.rs` | 新建 | 实现 StorageBackend trait（仅 get/delete/exists，put 由前端直传） |
| `backend/mod.rs` | 修改 | 导出 OssBackend |
| `api.rs` | 新增 | `POST /api/storage/upload-token` — 签发 STS 临时凭证 |
| `api.rs` | 新增 | `POST /api/storage/confirm-upload` — 前端上传完成后确认，记录元数据+扣配额 |
| `service.rs` | 修改 | StorageConfig 增加 OSS 配置；新增 STS 签发逻辑 |
| `main.rs` | 修改 | 环境变量选择后端 |
| `.env` | 修改 | 新增 STORAGE_BACKEND, OSS_ENDPOINT, OSS_BUCKET, OSS_ACCESS_KEY_ID, OSS_ACCESS_KEY_SECRET, OSS_STS_ROLE_ARN |
| `Cargo.toml` | 修改 | 增加 `aws-sdk-s3` + `aws-sdk-sts`（或阿里云 STS SDK） |

### 前端改动

| 文件 | 操作 | 内容 |
|------|------|------|
| `chat_file_mixin.dart` | 修改 | 上传流程从 multipart 改为：获取 token → 直传 OSS → confirm |
| `cloud_repository.dart` 或新建 `oss_upload_service.dart` | 新增 | OSS 直传封装（PUT object with STS headers） |
| 下载/查看逻辑 | 不动 | URL 规则不变 |

### 兼容策略

- `STORAGE_BACKEND=local`：开发环境，保持现有 multipart → LocalFs + ServeDir
- `STORAGE_BACKEND=oss`：生产环境，STS Token 直传 OSS
- 前端根据后端返回判断走哪条路径（或由配置决定）
- 历史数据：ServeDir 保留，旧链接继续可用

---

## 二、iOS 内购

### 商业模型

| 项 | 决定 |
|---|------|
| 套餐 | $0.99/月 = +1GB 云空间 |
| 计费模型 | Auto-Renewable Subscription（自动续费订阅） |
| 免费额度 | 100MB（不变） |
| 订阅中配额 | 100MB + 1GB = 1.1GB |
| 到期策略 | 方案 A：冻结上传，数据保留 |

---

## 定价依据

### 成本分析

| 费用项 | 单价 |
|--------|------|
| 阿里云 OSS 标准存储 | ¥0.12/GB/月 |
| 外网下行流量 | ¥0.50/GB |
| 1GB 用户综合月成本 | ~¥1.0~1.5 |

### 收入分析

| 项 | 金额 |
|----|------|
| iOS 售价 | $0.99/月（≈¥7.2） |
| 苹果抽成 30% | -¥2.16 |
| 实收 | ¥5.04/月 |
| 成本 | ~¥1.5/月 |
| **毛利** | **~¥3.5/用户/月** |

### 竞品参考

| 产品 | 方案 | 单价（¥/GB/月） |
|------|------|--------------|
| iCloud（中国区） | 50GB ¥6/月 | ¥0.12 |
| 百度网盘超会 | 5TB ¥30/月 | ¥0.006 |
| 闪讯（本方案） | 1GB $0.99/月 | ¥7.2 |

> 闪讯定价远高于裸存储服务，溢价来自 IM 附属功能的便利性（消息附件不丢失 + 多端同步 + 配额管理）。用户付费门槛低（$0.99 心理锚点），且目标用户是 iOS 端高意愿付费群体。

---

## 到期策略

采用 **方案 A（iCloud 模式）**：冻结上传，数据保留。

```
订阅中：  配额 = 100MB + 1GB = 1.1GB ✓ 正常使用
宽限期：  Apple Billing Grace Period（~16天），保持付费配额
正式到期：配额回退到 100MB

到期后行为：
  ✗ 超额时不能上传新文件
  ✗ 超额时不能发送图片/视频/文件消息
  ✓ 已有文件正常查看和下载
  ✓ 纯文本消息正常收发
  ✓ 可手动删除文件，回到 100MB 以内后恢复上传能力
```

---

## 技术栈

| 层 | 技术 | 说明 |
|---|------|------|
| iOS 支付 | StoreKit 2 / `in_app_purchase` 官方插件 | Flutter 官方维护 |
| 后端验单 | App Store Server API v2 | JWT 签名 + JWS 交易验证 |
| 服务端通知 | App Store Server Notifications V2 | 续费/退款/到期实时通知 |
| 数据库 | subscriptions 表 | 订阅状态 + 原始交易ID + 到期时间 |
| 配额联动 | 订阅状态变更 → user_storage_quota.quota_bytes | 升级/降级自动同步 |

---

## 开发范围

### 后端

| 模块 | 内容 |
|------|------|
| 数据模型 | subscriptions 表（user_id, product_id, original_transaction_id, status, expires_at） |
| 验单接口 | POST /api/subscriptions/verify — 接收客户端 receipt，调 App Store API 验证 |
| Server Notification | POST /api/subscriptions/notify — Apple 推送续费/退款/到期 |
| 配额升降级 | 验证通过 → quota_bytes += 1GB；到期 → quota_bytes 回退到 100MB |
| 订阅状态查询 | GET /api/subscriptions/status — 客户端查询当前订阅状态 |

### 前端

| 模块 | 内容 |
|------|------|
| 套餐展示 | 云空间页/设置页增加"扩容"入口，展示当前套餐和价格 |
| 发起购买 | `in_app_purchase` 调用 StoreKit 购买流程 |
| 购买验证 | 购买成功后将 receipt 发送到后端验证 |
| 恢复购买 | "恢复购买"按钮，处理换机场景 |
| 状态展示 | 订阅中/已到期/配额不足 提示 |
| 超额拦截 | 发送文件时检查配额，超额弹出扩容引导 |

---

## 流水线规划

| 步骤 | 状态 |
|------|------|
| 第 1 步 需求分析 | ⬜ |
| 第 2 步 后端设计 | ⬜ |
| 第 3 步 后端任务 | ⬜ |
| 第 4 步 交叉审查 | ⬜ |
| 第 5 步 后端实现 | ⬜ |
| 第 6 步 后端测试 | ⬜ |
| 第 7 步 前端设计 | ⬜ |
| 第 8 步 前端任务 | ⬜ |
| 第 9 步 前端审查 | ⬜ |
| 第 10 步 前端实现 | ⬜ |
| 第 11 步 前端测试 | ⬜ |
| 第 12 步 归档 | ⬜ |

---

## 暂不实现

| 功能 | 理由 |
|------|------|
| 多档位套餐（5GB/20GB） | 先单一套餐跑通流程 |
| Android Google Play 支付 | 本次只做 iOS |
| 微信/支付宝支付 | 后续根据需求追加 |
| 家庭共享 | Apple 家庭共享需额外开发 |
| 退款后数据处理 | Apple 退款通知收到后只回退配额，不删数据 |
| 优惠码/促销价 | 后续营销需求 |
