-- 应用注册表
CREATE TABLE IF NOT EXISTS apps (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 版本记录表
CREATE TABLE IF NOT EXISTS app_versions (
    id SERIAL PRIMARY KEY,
    app_id VARCHAR(64) NOT NULL REFERENCES apps(id),
    platform VARCHAR(32) NOT NULL,
    version VARCHAR(32) NOT NULL,
    download_url VARCHAR(512) NOT NULL,
    file_size BIGINT NOT NULL DEFAULT 0,
    sha256 VARCHAR(64),
    release_notes TEXT,
    force_update BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(app_id, platform, version)
);

CREATE INDEX IF NOT EXISTS idx_app_versions_lookup
    ON app_versions(app_id, platform, created_at DESC);

-- 初始化闪讯应用（app_id = '1'）
INSERT INTO apps (id, name, description) VALUES
    ('1', '闪讯', '跨平台即时通讯应用')
ON CONFLICT (id) DO NOTHING;
