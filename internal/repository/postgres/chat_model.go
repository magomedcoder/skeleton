package postgres

import (
	"time"

	"github.com/magomedcoder/legion/internal/domain"
)

type chatModel struct {
	Id         int       `gorm:"column:id;primaryKey;autoIncrement"`
	ChatType   int       `gorm:"column:chat_type;not null;default:1"`
	UserId     int       `gorm:"column:user_id;not null;index"`
	ReceiverId int       `gorm:"column:receiver_id;not null;index"`
	CreatedAt  time.Time `gorm:"column:created_at;not null"`
	UpdatedAt  time.Time `gorm:"column:updated_at;not null"`
}

func (chatModel) TableName() string {
	return "chats"
}

func chatModelToDomain(m *chatModel) *domain.Chat {
	if m == nil {
		return nil
	}

	return &domain.Chat{
		Id:         m.Id,
		ChatType:   m.ChatType,
		UserId:     m.UserId,
		ReceiverId: m.ReceiverId,
		CreatedAt:  m.CreatedAt,
		UpdatedAt:  m.UpdatedAt,
	}
}

func chatDomainToModel(c *domain.Chat) *chatModel {
	if c == nil {
		return nil
	}

	return &chatModel{
		Id:         c.Id,
		ChatType:   c.ChatType,
		UserId:     c.UserId,
		ReceiverId: c.ReceiverId,
		CreatedAt:  c.CreatedAt,
		UpdatedAt:  c.UpdatedAt,
	}
}
