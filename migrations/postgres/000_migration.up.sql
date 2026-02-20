CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users
(
    id              SERIAL PRIMARY KEY,
    username        VARCHAR(255) UNIQUE NOT NULL,
    password        VARCHAR(255)        NOT NULL,
    name            VARCHAR(255)        NOT NULL,
    surname         VARCHAR(255)        NOT NULL,
    role            INTEGER             NOT NULL DEFAULT 0,
    created_at      TIMESTAMP           NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP           NOT NULL DEFAULT NOW(),
    last_visited_at TIMESTAMP           NULL,
    deleted_at      TIMESTAMP           NULL
);

CREATE TABLE IF NOT EXISTS user_sessions
(
    id         SERIAL PRIMARY KEY,
    user_id    INTEGER     NOT NULL REFERENCES users (id),
    token      TEXT        NOT NULL UNIQUE,
    type       VARCHAR(20) NOT NULL,
    expires_at TIMESTAMP   NOT NULL,
    created_at TIMESTAMP   NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP   NULL
);

CREATE TABLE IF NOT EXISTS files
(
    id           UUID PRIMARY KEY      DEFAULT uuid_generate_v4(),
    filename     VARCHAR(255) NOT NULL,
    mime_type    VARCHAR(100) NULL,
    size         BIGINT       NOT NULL DEFAULT 0,
    storage_path TEXT         NOT NULL,
    created_at   TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chat_sessions
(
    id         UUID PRIMARY KEY      DEFAULT uuid_generate_v4(),
    user_id    INTEGER      NOT NULL REFERENCES users (id),
    title      VARCHAR(500) NOT NULL,
    model      VARCHAR(255) NOT NULL DEFAULT '',
    created_at TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP    NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP    NULL
);

CREATE TABLE IF NOT EXISTS chat_session_messages
(
    id                 UUID PRIMARY KEY     DEFAULT uuid_generate_v4(),
    session_id         UUID        NOT NULL REFERENCES chat_sessions (id),
    content            TEXT        NOT NULL,
    role               VARCHAR(20) NOT NULL,
    attachment_file_id UUID        NULL REFERENCES files (id) ON DELETE SET NULL,
    created_at         TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMP   NOT NULL DEFAULT NOW(),
    deleted_at         TIMESTAMP   NULL
);

CREATE TABLE IF NOT EXISTS chats
(
    id          SERIAL PRIMARY KEY,
    peer_type   INTEGER   NOT NULL DEFAULT 1,
    peer_id     INTEGER   NOT NULL,
    user_id     INTEGER   NOT NULL REFERENCES users (id),
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages
(
    id             BIGSERIAL PRIMARY KEY,
    peer_type      INTEGER   NOT NULL DEFAULT 1,
    peer_id        INTEGER   NOT NULL,
    from_peer_type INTEGER   NOT NULL DEFAULT 1,
    from_peer_id   INTEGER   NOT NULL,
    content        TEXT,
    created_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    deleted_at     TIMESTAMP NULL
);

CREATE TABLE IF NOT EXISTS user_deleted_messages
(
    user_id    INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    message_id BIGINT  NOT NULL,
    PRIMARY KEY (user_id, message_id)
);

CREATE TABLE IF NOT EXISTS projects
(
    id         UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    name       VARCHAR(255) NOT NULL,
    created_by INTEGER      NOT NULL REFERENCES users (id),
    created_at TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS project_members
(
    id         SERIAL PRIMARY KEY,
    project_id UUID      NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    user_id    INTEGER   NOT NULL REFERENCES users (id),
    created_by INTEGER   NOT NULL REFERENCES users (id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (project_id, user_id)
);

CREATE TABLE IF NOT EXISTS project_columns
(
    id         UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    project_id UUID         NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    title      VARCHAR(255) NOT NULL,
    color      VARCHAR(20)  NOT NULL DEFAULT '#9E9E9E',
    status_key VARCHAR(64)  NOT NULL,
    position   INTEGER      NOT NULL DEFAULT 0,
    UNIQUE (project_id, status_key)
);

CREATE TABLE IF NOT EXISTS project_tasks
(
    id          UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    project_id  UUID         NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    name        VARCHAR(255) NOT NULL,
    description TEXT,
    created_by  INTEGER      NOT NULL REFERENCES users (id),
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW(),
    assigner    INTEGER      NOT NULL REFERENCES users (id),
    executor    INTEGER      NOT NULL REFERENCES users (id),
    column_id   UUID         NULL REFERENCES project_columns (id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS project_task_comments
(
    id         UUID PRIMARY KEY   DEFAULT gen_random_uuid(),
    task_id    UUID      NOT NULL REFERENCES project_tasks (id) ON DELETE CASCADE,
    user_id    INTEGER   NOT NULL REFERENCES users (id),
    body       TEXT      NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS project_activity
(
    id         UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    project_id UUID        NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    task_id    UUID        NULL REFERENCES project_tasks (id) ON DELETE SET NULL,
    user_id    INTEGER     NOT NULL REFERENCES users (id),
    action     VARCHAR(64) NOT NULL,
    payload    TEXT        NULL,
    created_at TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_username ON users (username);
CREATE INDEX IF NOT EXISTS idx_users_role ON users (role);
CREATE INDEX IF NOT EXISTS idx_users_deleted_at ON users (deleted_at);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions (token);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires_at ON user_sessions (expires_at);
CREATE INDEX IF NOT EXISTS idx_user_sessions_deleted_at ON user_sessions (deleted_at);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user_id ON chat_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_created_at ON chat_sessions (created_at);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_deleted_at ON chat_sessions (deleted_at);
CREATE INDEX IF NOT EXISTS idx_chat_session_messages_session_id ON chat_session_messages (session_id);
CREATE INDEX IF NOT EXISTS idx_chat_session_messages_role ON chat_session_messages (role);
CREATE INDEX IF NOT EXISTS idx_chat_session_messages_created_at ON chat_session_messages (created_at);
CREATE INDEX IF NOT EXISTS idx_chat_session_messages_deleted_at ON chat_session_messages (deleted_at);
CREATE INDEX IF NOT EXISTS idx_chat_session_messages_attachment_file_id ON chat_session_messages (attachment_file_id);
CREATE INDEX IF NOT EXISTS idx_files_created_at ON files (created_at);
CREATE INDEX IF NOT EXISTS idx_chats_user_peer ON chats (user_id, peer_type, peer_id);
CREATE INDEX IF NOT EXISTS idx_chats_updated_at ON chats (updated_at);
CREATE INDEX IF NOT EXISTS idx_messages_peer_from_created_at ON messages (peer_type, peer_id, from_peer_type, from_peer_id, created_at);
CREATE INDEX IF NOT EXISTS idx_messages_deleted_at ON messages (deleted_at);
CREATE INDEX IF NOT EXISTS idx_user_deleted_messages_user_id ON user_deleted_messages (user_id);
CREATE INDEX IF NOT EXISTS idx_projects_created_by ON projects (created_by);
CREATE INDEX IF NOT EXISTS idx_projects_created_at ON projects (created_at);
CREATE INDEX IF NOT EXISTS idx_project_members_project_id ON project_members (project_id);
CREATE INDEX IF NOT EXISTS idx_project_members_user_id ON project_members (user_id);
CREATE INDEX IF NOT EXISTS idx_project_columns_project_id ON project_columns (project_id);
CREATE INDEX IF NOT EXISTS idx_project_columns_position ON project_columns (project_id, position);
CREATE INDEX IF NOT EXISTS idx_project_tasks_project_id ON project_tasks (project_id);
CREATE INDEX IF NOT EXISTS idx_project_tasks_column_id ON project_tasks (column_id);
CREATE INDEX IF NOT EXISTS idx_project_task_comments_task_id ON project_task_comments (task_id);
CREATE INDEX IF NOT EXISTS idx_project_task_comments_created_at ON project_task_comments (created_at);
CREATE INDEX IF NOT EXISTS idx_project_activity_project_id ON project_activity (project_id);
CREATE INDEX IF NOT EXISTS idx_project_activity_task_id ON project_activity (task_id);
CREATE INDEX IF NOT EXISTS idx_project_activity_created_at ON project_activity (created_at DESC);