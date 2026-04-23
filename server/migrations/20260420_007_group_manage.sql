-- 会话状态（0=正常, 1=已解散）
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS status SMALLINT NOT NULL DEFAULT 0;

-- 群公告
ALTER TABLE group_info ADD COLUMN IF NOT EXISTS announcement TEXT;
ALTER TABLE group_info ADD COLUMN IF NOT EXISTS announcement_updated_at TIMESTAMPTZ;
ALTER TABLE group_info ADD COLUMN IF NOT EXISTS announcement_updated_by BIGINT;
