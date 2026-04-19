-- 群号序列，从 10001 开始
CREATE SEQUENCE IF NOT EXISTS group_no_seq START WITH 10001;

-- 给 group_info 加群号字段
ALTER TABLE group_info ADD COLUMN IF NOT EXISTS group_no BIGINT UNIQUE DEFAULT nextval('group_no_seq');

-- 回填已有群的 group_no
UPDATE group_info SET group_no = nextval('group_no_seq') WHERE group_no IS NULL;

-- 入群申请表
CREATE TABLE IF NOT EXISTS group_join_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL,
    user_id BIGINT NOT NULL,
    message VARCHAR(200),
    status SMALLINT NOT NULL DEFAULT 0,  -- 0=待处理 1=已同意 2=已拒绝
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_group_join_requests_conv ON group_join_requests(conversation_id, status);
CREATE INDEX IF NOT EXISTS idx_group_join_requests_user ON group_join_requests(user_id, status);
