-- 认证系统相关表

-- 账户主体
CREATE TABLE accounts (
    id         BIGSERIAL    PRIMARY KEY,
    status     SMALLINT     NOT NULL DEFAULT 0,   -- 0:正常 1:禁用 2:注销
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_accounts_status ON accounts(status);

-- 用户资料（accounts 1:1）
CREATE TABLE user_profiles (
    account_id BIGINT       PRIMARY KEY REFERENCES accounts(id),
    nickname   VARCHAR(50)  NOT NULL,
    avatar     VARCHAR(500),
    bio        VARCHAR(200),
    gender     SMALLINT     DEFAULT 0,  -- 0:未知 1:男 2:女
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_profiles_nickname ON user_profiles(nickname);

-- 认证凭据（accounts 1:N）
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

-- 短信验证码
CREATE TABLE sms_codes (
    phone      VARCHAR(20)  PRIMARY KEY,
    code       VARCHAR(6)   NOT NULL,
    expires_at TIMESTAMPTZ  NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
