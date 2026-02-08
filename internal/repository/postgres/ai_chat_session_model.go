package postgres

import (
	"time"

	"github.com/magomedcoder/legion/internal/domain"
	"gorm.io/gorm"
)

type aiChatSessionModel struct {
	Id        string         `gorm:"column:id;primaryKey;type:uuid"`
	UserId    int            `gorm:"column:user_id;not null;index"`
	Title     string         `gorm:"column:title;size:500;not null"`
	Model     string         `gorm:"column:model;size:255;not null;default:''"`
	CreatedAt time.Time      `gorm:"column:created_at;not null"`
	UpdatedAt time.Time      `gorm:"column:updated_at;not null"`
	DeletedAt gorm.DeletedAt `gorm:"column:deleted_at;index"`
}

func (aiChatSessionModel) TableName() string {
	return "chat_sessions"
}

func aiChatSessionModelToDomain(m *aiChatSessionModel) *domain.AIChatSession {
	if m == nil {
		return nil
	}

	var deletedAt *time.Time
	if m.DeletedAt.Valid {
		t := m.DeletedAt.Time
		deletedAt = &t
	}

	return &domain.AIChatSession{
		Id:        m.Id,
		UserId:    m.UserId,
		Title:     m.Title,
		Model:     m.Model,
		CreatedAt: m.CreatedAt,
		UpdatedAt: m.UpdatedAt,
		DeletedAt: deletedAt,
	}
}

func aiChatSessionDomainToModel(s *domain.AIChatSession) *aiChatSessionModel {
	if s == nil {
		return nil
	}

	var deletedAt gorm.DeletedAt
	if s.DeletedAt != nil {
		deletedAt = gorm.DeletedAt{Time: *s.DeletedAt, Valid: true}
	}

	return &aiChatSessionModel{
		Id:        s.Id,
		UserId:    s.UserId,
		Title:     s.Title,
		Model:     s.Model,
		CreatedAt: s.CreatedAt,
		UpdatedAt: s.UpdatedAt,
		DeletedAt: deletedAt,
	}
}
