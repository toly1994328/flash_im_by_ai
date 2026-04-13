-- 群组扩展信息表
CREATE TABLE IF NOT EXISTS group_info (
    conversation_id UUID PRIMARY KEY,
    join_verification BOOLEAN NOT NULL DEFAULT FALSE,
    max_members INT NOT NULL DEFAULT 200,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 入群申请表
CREATE TABLE IF NOT EXISTS group_join_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id BIGINT NOT NULL,
    conversation_id UUID NOT NULL,
    message VARCHAR(200),
    status SMALLINT NOT NULL DEFAULT 0,
    handled_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_group_join_requests_conv
    ON group_join_requests(conversation_id, status);
CREATE INDEX IF NOT EXISTS idx_group_join_requests_user
    ON group_join_requests(user_id, status);

-- 系统用户（用于发送系统消息，如"XXX 创建了群聊"）
INSERT INTO accounts (id, status) VALUES (999999999, 0) ON CONFLICT (id) DO NOTHING;
INSERT INTO user_profiles (account_id, nickname, avatar) VALUES (999999999, '系统通知', NULL) ON CONFLICT (account_id) DO NOTHING;
