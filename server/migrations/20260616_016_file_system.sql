-- 文件对象表（全局去重，一个 hash 只存一条）
CREATE TABLE IF NOT EXISTS file_objects (
    id            BIGSERIAL    PRIMARY KEY,
    hash          VARCHAR(40)  NOT NULL UNIQUE,
    storage_path  VARCHAR(500) NOT NULL,
    size          BIGINT       NOT NULL,
    mime_type     VARCHAR(100) NOT NULL,
    mime_category VARCHAR(20)  NOT NULL,
    width         INT,
    height        INT,
    duration_ms   BIGINT,
    thumb_path    VARCHAR(500),
    ref_count     INT          NOT NULL DEFAULT 1,
    uploader_id   BIGINT       NOT NULL REFERENCES accounts(id),
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_file_objects_hash ON file_objects(hash);
CREATE INDEX idx_file_objects_uploader ON file_objects(uploader_id);

-- 用户云存储配额表
CREATE TABLE IF NOT EXISTS user_storage_quota (
    user_id     BIGINT       PRIMARY KEY REFERENCES accounts(id),
    used_bytes  BIGINT       NOT NULL DEFAULT 0,
    quota_bytes BIGINT       NOT NULL DEFAULT 104857600,
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- 文件引用关系表
CREATE TABLE IF NOT EXISTS file_references (
    id              BIGSERIAL   PRIMARY KEY,
    file_id         BIGINT      NOT NULL REFERENCES file_objects(id),
    message_id      UUID        NOT NULL REFERENCES messages(id),
    user_id         BIGINT      NOT NULL REFERENCES accounts(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_file_refs_file ON file_references(file_id);
CREATE INDEX idx_file_refs_message ON file_references(message_id);

-- 为已有用户补建配额记录
INSERT INTO user_storage_quota (user_id, used_bytes, quota_bytes, updated_at)
SELECT id, 0, 104857600, NOW()
FROM accounts
WHERE id NOT IN (SELECT user_id FROM user_storage_quota);
