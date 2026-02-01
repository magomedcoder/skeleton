package domain

import (
	"time"

	"github.com/google/uuid"
)

type ChatSession struct {
	Id        string
	UserId    int
	Title     string
	Model     string
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time
}

type Message struct {
	Id             string
	SessionId      string
	Content        string
	Role           MessageRole
	AttachmentName string
	CreatedAt      time.Time
	UpdatedAt      time.Time
	DeletedAt      *time.Time
}

func NewChatSession(userId int, title string, model string) *ChatSession {
	return &ChatSession{
		Id:        generateUUID(),
		UserId:    userId,
		Title:     title,
		Model:     model,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
}

func NewMessage(sessionId, content string, role MessageRole) *Message {
	return NewMessageWithAttachment(sessionId, content, role, "")
}

func NewMessageWithAttachment(sessionId, content string, role MessageRole, attachmentName string) *Message {
	return &Message{
		Id:             generateUUID(),
		SessionId:      sessionId,
		Content:        content,
		Role:           role,
		AttachmentName: attachmentName,
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}
}

func generateUUID() string {
	return uuid.New().String()
}
