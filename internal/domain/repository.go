package domain

import (
	"context"
)

type UserRepository interface {
	Create(ctx context.Context, user *User) error

	GetById(ctx context.Context, id int) (*User, error)

	GetByUsername(ctx context.Context, username string) (*User, error)

	List(ctx context.Context, page, pageSize int32) ([]*User, int32, error)

	Update(ctx context.Context, user *User) error
}

type TokenRepository interface {
	Create(ctx context.Context, token *Token) error

	GetByToken(ctx context.Context, token string) (*Token, error)

	DeleteByToken(ctx context.Context, token string) error

	DeleteByUserId(ctx context.Context, userId int, tokenType TokenType) error
}

type ChatSessionRepository interface {
	Create(ctx context.Context, session *ChatSession) error

	GetById(ctx context.Context, id string) (*ChatSession, error)

	GetByUserId(ctx context.Context, userID int, page, pageSize int32) ([]*ChatSession, int32, error)

	Update(ctx context.Context, session *ChatSession) error

	Delete(ctx context.Context, id string) error
}

type MessageRepository interface {
	Create(ctx context.Context, message *Message) error

	GetBySessionId(ctx context.Context, sessionID string, page, pageSize int32) ([]*Message, int32, error)
}

type OllamaRepository interface {
	SendMessage(ctx context.Context, sessionID string, messages []*Message) (chan string, error)

	CheckConnection(ctx context.Context) (bool, error)
}
