CREATE TABLE IF NOT EXISTS scan_sessions (
    token       VARCHAR(36) PRIMARY KEY,
    status      SMALLINT NOT NULL DEFAULT 0,  -- 0=pending 1=scanned 2=confirmed 3=cancelled
    user_id     BIGINT,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
