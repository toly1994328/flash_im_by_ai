CREATE TABLE IF NOT EXISTS email_codes (
    email       VARCHAR(255) PRIMARY KEY,
    code        VARCHAR(6) NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    request_ip  VARCHAR(45),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
