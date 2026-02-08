package postgres

import (
	"time"

	"github.com/magomedcoder/legion/internal/domain"
	"gorm.io/gorm"
)

type aiChatMessageModel struct {
	Id               string         `gorm:"column:id;primaryKey;type:uuid"`
	SessionId        string         `gorm:"column:session_id;type:uuid;not null;index"`
	Content          string         `gorm:"column:content;type:text;not null"`
	Role             string         `gorm:"column:role;size:20;not null"`
	AttachmentFileId *string        `gorm:"column:attachment_file_id;type:uuid"`
	CreatedAt        time.Time      `gorm:"column:created_at;not null"`
	UpdatedAt        time.Time      `gorm:"column:updated_at;not null"`
	DeletedAt        gorm.DeletedAt `gorm:"column:deleted_at;index"`
}

func (aiChatMessageModel) TableName() string {
	return "chat_session_messages"
}

func aiChatMessageModelToDomain(m *aiChatMessageModel) *domain.AIChatMessage {
	if m == nil {
		return nil
	}

	attachmentName := ""
	if m.AttachmentFileId != nil {
		attachmentName = *m.AttachmentFileId
	}

	var deletedAt *time.Time
	if m.DeletedAt.Valid {
		t := m.DeletedAt.Time
		deletedAt = &t
	}

	return &domain.AIChatMessage{
		Id:             m.Id,
		SessionId:      m.SessionId,
		Content:        m.Content,
		Role:           domain.AIChatMessageRole(m.Role),
		AttachmentName: attachmentName,
		CreatedAt:      m.CreatedAt,
		UpdatedAt:      m.UpdatedAt,
		DeletedAt:      deletedAt,
	}
}

func aiChatMessageDomainToModel(msg *domain.AIChatMessage) *aiChatMessageModel {
	if msg == nil {
		return nil
	}

	var attachmentFileId *string
	if msg.AttachmentName != "" {
		attachmentFileId = &msg.AttachmentName
	}

	var deletedAt gorm.DeletedAt
	if msg.DeletedAt != nil {
		deletedAt = gorm.DeletedAt{Time: *msg.DeletedAt, Valid: true}
	}

	return &aiChatMessageModel{
		Id:               msg.Id,
		SessionId:        msg.SessionId,
		Content:          msg.Content,
		Role:             string(msg.Role),
		AttachmentFileId: attachmentFileId,
		CreatedAt:        msg.CreatedAt,
		UpdatedAt:        msg.UpdatedAt,
		DeletedAt:        deletedAt,
	}
}
