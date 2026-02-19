package postgres

import (
	"time"

	"github.com/magomedcoder/legion/internal/domain"
)

type chatModel struct {
	Id        int       `gorm:"column:id;primaryKey;autoIncrement"`
	PeerType  int       `gorm:"column:peer_type;not null;default:1"`
	PeerId    int       `gorm:"column:peer_id;not null"`
	UserId    int       `gorm:"column:user_id;not null;index"`
	CreatedAt time.Time `gorm:"column:created_at;not null"`
	UpdatedAt time.Time `gorm:"column:updated_at;not null"`
}

func (chatModel) TableName() string {
	return "chats"
}

func chatModelToDomain(m *chatModel) *domain.Chat {
	if m == nil {
		return nil
	}

	return &domain.Chat{
		Id:        m.Id,
		PeerType:  m.PeerType,
		PeerId:    m.PeerId,
		UserId:    m.UserId,
		CreatedAt: m.CreatedAt,
		UpdatedAt: m.UpdatedAt,
	}
}

func chatDomainToModel(c *domain.Chat) *chatModel {
	if c == nil {
		return nil
	}

	return &chatModel{
		Id:        c.Id,
		PeerType:  c.PeerType,
		PeerId:    c.PeerId,
		UserId:    c.UserId,
		CreatedAt: c.CreatedAt,
		UpdatedAt: c.UpdatedAt,
	}
}
