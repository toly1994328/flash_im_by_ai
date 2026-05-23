-- 登录日志表
CREATE TABLE login_logs (
    id          BIGSERIAL    PRIMARY KEY,
    account_id  BIGINT       NOT NULL REFERENCES accounts(id),
    login_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    ip          VARCHAR(45),
    platform    VARCHAR(20),
    device_name VARCHAR(100),
    device_id   VARCHAR(100),
    app_version VARCHAR(20)
);

CREATE INDEX idx_login_logs_account ON login_logs(account_id);
CREATE INDEX idx_login_logs_time ON login_logs(login_at DESC);

-- 系统用户（id=0）：用于群聊系统消息的 sender_id
INSERT INTO accounts (id, status, created_at, updated_at)
VALUES (0, 0, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_profiles (account_id, nickname, avatar, signature, updated_at)
VALUES (0, '系统通知', 'identicon:system', '系统消息', NOW())
ON CONFLICT (account_id) DO NOTHING;

-- 闪讯团队（id=100000000）：官方用户，首次登录欢迎消息的发送者
INSERT INTO accounts (id, status, created_at, updated_at)
VALUES (100000000, 0, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_profiles (account_id, nickname, avatar, signature, updated_at)
VALUES (100000000, '闪讯团队', 'identicon:team', '闪讯官方团队', NOW())
ON CONFLICT (account_id) DO NOTHING;

SELECT setval('accounts_id_seq', GREATEST((SELECT MAX(id) FROM accounts WHERE id < 100000000), 1));
