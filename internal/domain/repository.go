package domain

import (
	"context"
)

type UserRepository interface {
	Create(ctx context.Context, user *User) error

	GetByID(ctx context.Context, id int) (*User, error)

	GetByEmail(ctx context.Context, email string) (*User, error)

	Update(ctx context.Context, user *User) error
}

type TokenRepository interface {
	Create(ctx context.Context, token *Token) error

	GetByToken(ctx context.Context, token string) (*Token, error)

	DeleteByToken(ctx context.Context, token string) error

	DeleteByUserID(ctx context.Context, userID int, tokenType TokenType) error
}
