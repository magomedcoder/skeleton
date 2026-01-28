CREATE TABLE IF NOT EXISTS users
(
    id         SERIAL PRIMARY KEY,
    username   VARCHAR(255) UNIQUE NOT NULL,
    password   VARCHAR(255)        NOT NULL,
    name       VARCHAR(255)        NOT NULL,
    surname    VARCHAR(255)        NOT NULL,
    role       INTEGER             NOT NULL DEFAULT 0,
    created_at TIMESTAMP           NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP           NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP           NULL
);

CREATE TABLE IF NOT EXISTS tokens
(
    id         SERIAL PRIMARY KEY,
    user_id    INTEGER     NOT NULL REFERENCES users (id),
    token      TEXT        NOT NULL UNIQUE,
    type       VARCHAR(20) NOT NULL,
    expires_at TIMESTAMP   NOT NULL,
    created_at TIMESTAMP   NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP   NULL
);

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS chat_sessions
(
    id         UUID PRIMARY KEY      DEFAULT uuid_generate_v4(),
    user_id    INTEGER      NOT NULL REFERENCES users (id),
    title      VARCHAR(500) NOT NULL,
    created_at TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP    NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP    NULL
);

CREATE TABLE IF NOT EXISTS messages
(
    id         UUID PRIMARY KEY     DEFAULT uuid_generate_v4(),
    session_id UUID        NOT NULL REFERENCES chat_sessions (id),
    content    TEXT        NOT NULL,
    role       VARCHAR(20) NOT NULL,
    created_at TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP   NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP   NULL
);

CREATE INDEX idx_users_username ON users (username);
CREATE INDEX IF NOT EXISTS idx_users_role ON users (role);
CREATE INDEX IF NOT EXISTS idx_users_deleted_at ON users (deleted_at);
CREATE INDEX IF NOT EXISTS idx_tokens_user_id ON tokens (user_id);
CREATE INDEX IF NOT EXISTS idx_tokens_token ON tokens (token);
CREATE INDEX IF NOT EXISTS idx_tokens_expires_at ON tokens (expires_at);
CREATE INDEX IF NOT EXISTS idx_tokens_deleted_at ON tokens (deleted_at);
CREATE INDEX idx_chat_sessions_user_id ON chat_sessions (user_id);
CREATE INDEX idx_chat_sessions_created_at ON chat_sessions (created_at);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_deleted_at ON chat_sessions (deleted_at);
CREATE INDEX idx_messages_session_id ON messages (session_id);
CREATE INDEX idx_messages_role ON messages (role);
CREATE INDEX idx_messages_created_at ON messages (created_at);
CREATE INDEX IF NOT EXISTS idx_messages_deleted_at ON messages (deleted_at);