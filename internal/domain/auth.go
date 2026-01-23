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
	Id        int
	UserId    int
	Token     string
	Type      TokenType
	ExpiresAt time.Time
	CreatedAt time.Time
}

func NewToken(userId int, token string, tokenType TokenType, expiresAt time.Time) *Token {
	return &Token{
		Id:        0,
		UserId:    userId,
		Token:     token,
		Type:      tokenType,
		ExpiresAt: expiresAt,
		CreatedAt: time.Now(),
	}
}

func (t *Token) IsExpired() bool {
	return time.Now().After(t.ExpiresAt)
}
