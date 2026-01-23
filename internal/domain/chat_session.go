package domain

import (
	"time"

	"github.com/google/uuid"
)

type ChatSession struct {
	Id        string
	UserId    int
	Title     string
	CreatedAt time.Time
	UpdatedAt time.Time
}

type Message struct {
	Id        string
	SessionId string
	Content   string
	Role      MessageRole
	CreatedAt time.Time
	UpdatedAt time.Time
}

func NewChatSession(userId int, title string) *ChatSession {
	return &ChatSession{
		Id:        generateUUID(),
		UserId:    userId,
		Title:     title,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
}

func NewMessage(sessionId, content string, role MessageRole) *Message {
	return &Message{
		Id:        generateUUID(),
		SessionId: sessionId,
		Content:   content,
		Role:      role,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
}

func generateUUID() string {
	return uuid.New().String()
}
