package domain

import (
	"github.com/magomedcoder/legion/pkg"
	"time"
)

type AIChatMessageRole string

const (
	AIChatMessageRoleSystem    AIChatMessageRole = "system"
	AIChatMessageRoleUser      AIChatMessageRole = "user"
	AIChatMessageRoleAssistant AIChatMessageRole = "assistant"
)

type AIChatSession struct {
	Id        string
	UserId    int
	Title     string
	Model     string
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time
}

type AIChatMessage struct {
	Id             string
	SessionId      string
	Content        string
	Role           AIChatMessageRole
	AttachmentName string
	CreatedAt      time.Time
	UpdatedAt      time.Time
	DeletedAt      *time.Time
}

func NewAIChatSession(userId int, title string, model string) *AIChatSession {
	return &AIChatSession{
		Id:        pkg.GenerateUUID(),
		UserId:    userId,
		Title:     title,
		Model:     model,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
}

func NewAIChatMessage(sessionId, content string, role AIChatMessageRole) *AIChatMessage {
	return NewAIChatMessageWithAttachment(sessionId, content, role, "")
}

func NewAIChatMessageWithAttachment(sessionId, content string, role AIChatMessageRole, attachmentName string) *AIChatMessage {
	return &AIChatMessage{
		Id:             pkg.GenerateUUID(),
		SessionId:      sessionId,
		Content:        content,
		Role:           role,
		AttachmentName: attachmentName,
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}
}

func (ai *AIChatMessage) AIToMap() map[string]interface{} {
	return map[string]interface{}{
		"role":    string(ai.Role),
		"content": ai.Content,
	}
}

func AIFromProtoRole(role string) AIChatMessageRole {
	switch role {
	case "system":
		return AIChatMessageRoleSystem
	case "user":
		return AIChatMessageRoleUser
	case "assistant":
		return AIChatMessageRoleAssistant
	default:
		return AIChatMessageRoleUser
	}
}

func AIToProtoRole(role AIChatMessageRole) string {
	return string(role)
}
