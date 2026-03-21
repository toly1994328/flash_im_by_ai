---
module: auth
version: v0.0.1
date: 2025-06-15
tags: [认证, 登录, JWT, 短信验证码, 密码设置]
---

# Auth 模块 — Server 设计报告

## 1. 目标

- 短信验证码登录（登录即注册）
- 密码登录
- 设置/修改密码接口
- 登录响应返回 `has_password` 字段，供客户端引导密码设置

---

## 2. 现状分析

### 当前实现

- PostgreSQL 持久化，4 张表（accounts, user_profiles, auth_credentials, sms_codes）
- JWT secret 从环境变量读取，7 天有效期
- 短信验证码登录（登录即注册）+ 密码登录
- Argon2 密码哈希

### 待补充

- 短信登录自动注册时不设密码，`credential` 为 NULL → 密码登录不可用
- 缺少"设置/修改密码"接口
- 登录响应未告知客户端是否已设密码

### 基础设施就绪情况

- PostgreSQL 安装脚本已完成（`scripts/install_postgres.ps1`）
- 数据库：`flash_im`（postgres://postgres:postgres@localhost:5432/flash_im）
- 服务端口：9600

---

## 3. 数据模型与接口

### 数据模型

采用三表分离 + 验证码表的设计，共 4 张表。

#### accounts — 账户主体

纯粹的身份标识，不含任何业务信息。

```sql
CREATE TABLE accounts (
    id         BIGSERIAL    PRIMARY KEY,
    status     SMALLINT     NOT NULL DEFAULT 0,   -- 0:正常 1:禁用 2:注销
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_accounts_status ON accounts(status);
```

#### user_profiles — 用户资料

与 accounts 1:1 关系，存放展示信息。

```sql
CREATE TABLE user_profiles (
    account_id BIGINT       PRIMARY KEY REFERENCES accounts(id),
    nickname   VARCHAR(50)  NOT NULL,
    avatar     VARCHAR(500),
    bio        VARCHAR(200),
    gender     SMALLINT     DEFAULT 0,  -- 0:未知 1:男 2:女
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_profiles_nickname ON user_profiles(nickname);
```

#### auth_credentials — 认证凭据

与 accounts 1:N 关系，支持一个账户绑定多种登录方式。

```sql
CREATE TABLE auth_credentials (
    id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id BIGINT       NOT NULL REFERENCES accounts(id),
    auth_type  VARCHAR(20)  NOT NULL,     -- 'phone', 'email', 'wechat', 'google'
    identifier VARCHAR(100) NOT NULL,     -- 手机号/邮箱/openid
    credential VARCHAR(255),              -- 密码hash，第三方登录为 NULL
    verified   BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    UNIQUE(auth_type, identifier)
);

CREATE INDEX idx_auth_credentials_account ON auth_credentials(account_id);
```

#### sms_codes — 短信验证码

替代当前内存中的 HashMap，带过期时间。

```sql
CREATE TABLE sms_codes (
    phone      VARCHAR(20)  PRIMARY KEY,
    code       VARCHAR(6)   NOT NULL,
    expires_at TIMESTAMPTZ  NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
```

#### 设计要点

| 决策 | 理由 |
|------|------|
| accounts 与 user_profiles 分离 | 认证层不需要关心用户资料，职责清晰 |
| auth_credentials 1:N | 一个账户可同时绑定手机号、邮箱、微信等 |
| `(auth_type, identifier)` 唯一约束 | 同一手机号/邮箱不能注册两个账户 |
| sms_codes 用数据库表 | 当前阶段不需要 Redis，数据库表足够，后续可替换 |
| BIGSERIAL 作为 account id | 自增整数，简单高效，JWT payload 体积小 |
| credential 允许 NULL | 短信登录自动注册时不设密码，后续用户可主动设置 |

#### ER 关系

```mermaid
erDiagram
    accounts ||--|| user_profiles : "1:1"
    accounts ||--o{ auth_credentials : "1:N"

    accounts {
        bigserial id PK
        smallint status "0正常 1禁用 2注销"
        timestamptz created_at
        timestamptz updated_at
    }

    user_profiles {
        bigint account_id PK,FK
        varchar nickname
        varchar avatar
        varchar bio
        smallint gender "0未知 1男 2女"
        timestamptz updated_at
    }

    auth_credentials {
        uuid id PK
        bigint account_id FK
        varchar auth_type "phone/email/wechat/google"
        varchar identifier "手机号/邮箱/openid"
        varchar credential "密码hash，可为NULL"
        boolean verified
        timestamptz created_at
    }

    sms_codes {
        varchar phone PK
        varchar code
        timestamptz expires_at
        timestamptz created_at
    }
```

### 接口契约

#### 现有接口（需调整）

```
POST /auth/sms          发送验证码
POST /auth/login        统一登录（短信/密码）
GET  /user/profile      获取当前用户信息（需 Token）
```

登录响应增加 `has_password` 字段：

```json
{
  "token": "eyJ...",
  "user_id": 1,
  "has_password": false
}
```

客户端根据 `has_password` 决定登录成功后是否弹出密码设置引导。

#### 新增接口

**POST /auth/password** — 设置密码（需 Token）

已登录状态下直接设置新密码，不区分首次/修改：

```json
// 请求
{ "new_password": "abc123" }
// 响应 200
{ "message": "密码设置成功" }
```

错误情况：
- 401 — Token 无效
- 400 — new_password 为空或过短（最少 6 位）

#### JWT 策略

| 项目 | 方案 |
|------|------|
| 算法 | HS256 |
| Secret | 从环境变量 `JWT_SECRET` 读取 |
| 有效期 | 7 天 |
| Payload | `{ sub: account_id, exp, iat }` |
| Refresh Token | 暂不实现，后续需要时再加 |

---

## 4. 核心流程

### 短信验证码登录（登录即注册）

```mermaid
sequenceDiagram
    participant C as 客户端
    participant S as 服务端
    participant DB as 数据库

    C->>S: POST /auth/sms { phone }
    S->>DB: INSERT/UPDATE sms_codes (code, expires_at)
    S-->>C: { code } (测试阶段返回)

    C->>S: POST /auth/login { phone, type:sms, credential:code }
    S->>DB: SELECT sms_codes WHERE phone = ?
    S->>S: 验证 code + expires_at

    S->>DB: SELECT auth_credentials WHERE phone = ?

    alt 用户不存在
        S->>DB: BEGIN
        S->>DB: INSERT accounts
        S->>DB: INSERT user_profiles
        S->>DB: INSERT auth_credentials (credential = NULL)
        S->>DB: COMMIT
    end

    S->>DB: SELECT credential IS NOT NULL → has_password
    S->>S: 生成 JWT
    S-->>C: { token, user_id, has_password }
```

### 密码登录

```mermaid
sequenceDiagram
    participant C as 客户端
    participant S as 服务端
    participant DB as 数据库

    C->>S: POST /auth/login { phone, type:password, credential:password }
    S->>DB: SELECT auth_credentials WHERE phone = ?

    alt credential 为 NULL
        S-->>C: 401 (未设置密码)
    end

    S->>S: Argon2 验证密码
    S->>S: 生成 JWT
    S-->>C: { token, user_id, has_password: true }
```

### 设置密码

已登录用户（持有有效 Token）可直接设置新密码，无需提供旧密码。无论是首次设置还是重置，统一走同一逻辑。

```mermaid
sequenceDiagram
    participant C as 客户端
    participant S as 服务端
    participant DB as 数据库

    C->>S: POST /auth/password { new_password } (Token)
    S->>S: 从 Token 解析 account_id
    S->>S: 校验 new_password（≥6 位）
    S->>S: Argon2 hash(new_password)
    S->>DB: UPDATE auth_credentials SET credential = hash WHERE account_id = ?
    S-->>C: 200 { message: "密码设置成功" }
```

---

## 5. 项目结构与技术决策

### 项目结构

```
server/src/
├── main.rs              # 入口：启动服务、组装路由
├── state.rs             # 共享状态：AppState（数据库连接池）
└── auth/
    ├── mod.rs           # 模块声明
    ├── routes.rs        # 路由定义
    ├── handler.rs       # 处理逻辑：发送验证码、登录、获取资料、设置密码
    ├── jwt.rs           # JWT 工具：生成和验证 Token
    └── model.rs         # 数据模型：请求/响应结构
```

### 演进策略

**当前：单 crate + PostgreSQL**

在现有 `server/` 中直接接入数据库，不拆 crate。理由：
- 当前代码量小，拆分带来的复杂度大于收益
- 先跑通核心流程，验证数据库设计

**后续：workspace 多 crate**

等会话、消息、好友等模块加入后，再拆分为：
```
server/
├── crates/
│   ├── app-core/        # 错误类型、通用响应
│   ├── app-database/    # 连接池、迁移
│   ├── app-auth/        # 认证模块
│   ├── app-user/        # 用户模块
│   ├── im-conversation/ # 会话
│   ├── im-message/      # 消息
│   └── im-server/       # 主服务入口
```

### 改动清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `server/src/auth/model.rs` | 修改 | LoginResponse 增加 `has_password`，新增 PasswordRequest |
| `server/src/auth/handler.rs` | 修改 | login 返回 has_password，新增 `set_password` handler |
| `server/src/auth/routes.rs` | 修改 | 新增 `POST /auth/password` 路由 |

数据库表结构无需变更，`auth_credentials.credential` 已支持 NULL。

---

## 6. 暂不实现

| 功能 | 理由 |
|------|------|
| Redis 缓存 | 验证码用数据库表足够，后续量大再换 |
| Refresh Token | 单 token + 7天过期，当前阶段够用 |
| 第三方登录（微信/Google） | 表结构已预留 auth_type，实现推后 |
| 邮箱登录 | 同上，表结构支持，实现推后 |
| 账户封禁/注销逻辑 | status 字段已预留，推后实现 |
| 密码找回（忘记密码） | 需要短信验证 + 重置流程，后续加 |
