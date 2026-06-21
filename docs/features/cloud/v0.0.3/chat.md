# 云空间 OSS 存储接入（cloud/v0.0.3）

> 版本：v0.40.0  
> 状态：进行中  
> 分支：feature/v0.40.0

---

## 核心方案

双后端模式：根据用户订阅状态决定上传路径。

| 用户类型 | 判定条件 | 上传方式 | 文件访问 |
|----------|---------|---------|---------|
| 普通用户 | 无活跃订阅 | 现有 multipart → 本地磁盘 | baseUrl + /uploads/path |
| 付费用户 | 有活跃订阅（user_subscriptions） | STS Token → 前端直传 OSS | https://bucket.oss.../path |

激活方式（本期）：兑换码  
激活方式（下期）：iOS 内购

- 数据库 `storage_path` 继续存相对路径，不动
- 前端已有逻辑：没有 `https://` 开头 → 拼 baseUrl；有 → 直接用。不动
- 普通用户上传逻辑完全不变（现有 multipart 接口保留）
- 付费用户走新接口：获取 STS Token → 直传 OSS → confirm

---

## 上传架构

### 普通用户（不变）

```
前端 → POST /api/upload/image (multipart) → 后端 Service → LocalFs.put() → 本地磁盘
前端 ← 返回 /uploads/original/xxx.jpg
```

### 付费用户（新增）

```
前端 → POST /api/storage/upload-token → 后端校验配额+签发 STS 临时凭证
前端 → PUT 文件直传阿里云 OSS（携带 STS Token）
前端 → POST /api/storage/confirm-upload → 后端记录元数据 + 扣减配额
前端 ← 返回 https://bucket.oss-cn-xxx.aliyuncs.com/original/xxx.jpg
```

---

## 后端改动

| 文件 | 操作 | 内容 |
|------|------|------|
| `backend/oss.rs` | 新建 | OssBackend（get/delete/exists 对接 S3 兼容协议） |
| `backend/mod.rs` | 修改 | 导出 OssBackend |
| `api.rs` | 新增 | `POST /api/storage/upload-token` — 签发 STS 临时凭证 |
| `api.rs` | 新增 | `POST /api/storage/confirm-upload` — 确认上传，记录元数据+扣配额 |
| `service.rs` | 修改 | StorageConfig 增加 OSS 配置；新增 STS 签发和 confirm 逻辑 |
| `main.rs` | 修改 | 初始化 OssBackend（当 OSS 配置存在时） |
| `.env` | 修改 | 新增 OSS_ENDPOINT, OSS_BUCKET, OSS_ACCESS_KEY_ID 等 |
| `Cargo.toml` | 修改 | 增加 aws-sdk-s3 + aws-sdk-sts |
| **新模块 `app-subscription`** | 新建 | 订阅计划 + 用户订阅 + 兑换码（独立模块） |

### 订阅模块（app-subscription）

```
server/modules/app-subscription/
├── src/
│   ├── lib.rs
│   ├── model.rs         -- subscription_plans, user_subscriptions, redeem_codes
│   ├── repository.rs    -- CRUD
│   ├── service.rs       -- 兑换逻辑、订阅状态查询、配额计算
│   └── api.rs           -- 路由：兑换码兑换、订阅状态查询
└── Cargo.toml
```

接口：
- `POST /api/subscriptions/redeem` — 兑换码激活订阅
- `GET /api/subscriptions/status` — 查询当前订阅状态（含是否 OSS 可用）

数据表：
- `subscription_plans` — 计划定义
- `user_subscriptions` — 用户订阅记录
- `redeem_codes` — 兑换码

## 前端改动

| 文件 | 操作 | 内容 |
|------|------|------|
| `chat_file_mixin.dart` | 修改 | 上传前查订阅状态，有活跃订阅走 OSS 直传 |
| 新建 `oss_uploader.dart` | 新建 | OSS 直传封装（获取 token → PUT → confirm） |
| 兑换码输入 UI | 新建 | 设置/云空间页增加"兑换码"入口，输入+验证+刷新状态 |
| 订阅状态展示 | 新建 | 云空间页显示当前订阅（Pro / 免费） |
| 下载/查看逻辑 | 不动 | URL 规则不变 |

---

## 判定逻辑

```
用户是否走 OSS 上传：
  查 user_subscriptions 表是否有 status='active' 且 expires_at > NOW() 的记录
  有 → OSS 直传
  无 → 本地 multipart（现有逻辑）

配额计算（本期）：
  总配额 = 基础 100MB + SUM(活跃订阅计划的 storage_bytes)

激活订阅的方式（本期）：
  用户输入兑换码 → POST /api/subscriptions/redeem → 验证码有效性
  → 创建 user_subscriptions 记录 → 更新 quota → WS 通知前端刷新

涉及新表：
  subscription_plans     — 计划定义（code, name, storage_bytes, features, price）
  user_subscriptions     — 用户订阅记录（user_id, plan_id, status, starts_at, expires_at）
  redeem_codes           — 兑换码（code, plan_id, duration_days, max_uses, used_count, expires_at）
```

---

## 安全设计

- 所有密钥（OSS AK/SK、STS Role ARN）仅在 `.env` 中，已从 git 追踪移除
- STS Token 有效期 15 分钟，限定上传路径前缀 `users/{uid}/`
- confirm-upload 接口后端会验证 OSS 上文件是否真实存在
- 配额校验 100% 在服务端，客户端跳过检查也会被后端拒绝

---

## 暂不实现

| 功能 | 理由 |
|------|------|
| iOS 内购 | 下版本，先把 OSS 链路跑通 |
| 付费套餐展示 | 下版本 |
| 到期降级 | 下版本 |
| CDN 加速 | 先跑通基础链路 |
| 大文件分片上传 | 当前 50MB 限制够用 |

---

## TODO（后续版本）

- [ ] `user_quota_rewards` 表：一次性配额奖励（签到领空间、邀请好友送额度、活动赠送）
- [ ] 配额计算改为：基础 100MB + 订阅配额 + 奖励配额
- [ ] 奖励支持过期时间（永久/限时）
- [ ] iOS 内购对接 App Store Server API v2
- [ ] 到期后冻结上传（方案 A）
- [ ] 多档位套餐（5GB/20GB）

---

## 测试方式

1. 后端启动后，通过管理接口或 SQL 插入测试兑换码：
```sql
INSERT INTO subscription_plans (code, name, storage_bytes, features, price_cents, period_days)
VALUES ('cloud_pro', '云空间 Pro', 1073741824, '{"oss_upload": true}', 99, 30);

INSERT INTO redeem_codes (code, plan_id, duration_days, max_uses)
VALUES ('TEST-1234-5678', 1, 30, 10);
```

2. 前端输入兑换码 `TEST-1234-5678` → 激活订阅 → 上传走 OSS

---

## 定价备忘（下版本用）

| 项 | 值 |
|---|---|
| 套餐 | $0.99/月 = +1GB |
| 模型 | Auto-Renewable Subscription |
| 到期策略 | 冻结上传，数据保留 |
| 毛利 | ~¥3.5/用户/月 |
