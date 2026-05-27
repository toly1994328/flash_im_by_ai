CREATE TABLE IF NOT EXISTS verify_codes (
    identifier  VARCHAR(255) NOT NULL,
    channel     VARCHAR(10) NOT NULL,
    scene       VARCHAR(20) NOT NULL DEFAULT 'login',
    code        VARCHAR(6) NOT NULL,
    status      SMALLINT NOT NULL DEFAULT 0,  -- 0=待验证 1=已使用 2=已过期
    expires_at  TIMESTAMPTZ NOT NULL,
    request_ip  VARCHAR(45),
    sender      VARCHAR(255),  -- 发送方邮箱（EMAIL_USERNAME），用于统计和多邮箱切换
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (identifier, channel, scene)
);
