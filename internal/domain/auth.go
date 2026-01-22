package domain

import (
	"time"
)

type TokenType string

const (
	TokenTypeAccess  TokenType = "access"
	TokenTypeRefresh TokenType = "refresh"
)

type Token struct {
	ID        int
	UserID    int
	Token     string
	Type      TokenType
	ExpiresAt time.Time
	CreatedAt time.Time
}

func NewToken(userID int, token string, tokenType TokenType, expiresAt time.Time) *Token {
	return &Token{
		ID:        0,
		UserID:    userID,
		Token:     token,
		Type:      tokenType,
		ExpiresAt: expiresAt,
		CreatedAt: time.Now(),
	}
}

func (t *Token) IsExpired() bool {
	return time.Now().After(t.ExpiresAt)
}
