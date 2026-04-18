-- 群组扩展信息表
CREATE TABLE IF NOT EXISTS group_info (
    conversation_id UUID PRIMARY KEY,
    join_verification BOOLEAN NOT NULL DEFAULT FALSE,
    max_members INT NOT NULL DEFAULT 200,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 系统用户（用于发送系统消息，如"XXX 创建了群聊"）
INSERT INTO accounts (id, status) VALUES (0, 0) ON CONFLICT (id) DO NOTHING;
INSERT INTO user_profiles (account_id, nickname, avatar) VALUES (0, '系统通知', NULL) ON CONFLICT (account_id) DO NOTHING;
