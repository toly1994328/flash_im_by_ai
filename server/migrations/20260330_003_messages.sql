-- 消息表
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id),
    sender_id BIGINT NOT NULL,
    seq BIGINT NOT NULL,
    type SMALLINT NOT NULL DEFAULT 0,
    content TEXT NOT NULL,
    extra JSONB,
    status SMALLINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation_seq ON messages(conversation_id, seq DESC);

-- 会话序列号表
CREATE TABLE conversation_seq (
    conversation_id UUID PRIMARY KEY REFERENCES conversations(id),
    current_seq BIGINT NOT NULL DEFAULT 0
);
