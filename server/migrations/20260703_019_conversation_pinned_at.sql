-- 新增 pinned_at 字段，用于置顶排序（线上无历史数据，无需回填）
ALTER TABLE conversation_members ADD COLUMN pinned_at TIMESTAMPTZ;

COMMENT ON COLUMN conversation_members.pinned_at IS '置顶时间，NULL 表示未置顶';
