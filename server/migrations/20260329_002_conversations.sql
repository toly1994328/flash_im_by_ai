-- 会话表
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type SMALLINT NOT NULL DEFAULT 0,       -- 0:单聊 1:群聊
    name VARCHAR(100),                       -- 群聊名称，单聊为 null
    avatar VARCHAR(500),                     -- 群头像
    owner_id BIGINT,                         -- 群主
    last_message_at TIMESTAMPTZ,
    last_message_preview VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_conversations_type ON conversations(type);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at DESC);

-- 会话成员表
CREATE TABLE conversation_members (
    conversation_id UUID NOT NULL,
    user_id BIGINT NOT NULL,
    unread_count INT NOT NULL DEFAULT 0,
    last_read_seq BIGINT NOT NULL DEFAULT 0,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
    is_muted BOOLEAN NOT NULL DEFAULT FALSE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (conversation_id, user_id)
);

CREATE INDEX idx_conversation_members_user ON conversation_members(user_id);
