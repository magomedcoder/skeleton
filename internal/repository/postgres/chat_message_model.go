package postgres

import (
	"time"

	"github.com/magomedcoder/legion/internal/domain"
)

type chatMessageModel struct {
	Id           int64     `gorm:"column:id;primaryKey;autoIncrement"`
	PeerType     int       `gorm:"column:peer_type;not null;default:1"`
	PeerId       int       `gorm:"column:peer_id;not null"`
	FromPeerType int       `gorm:"column:from_peer_type;not null;default:1"`
	FromPeerId   int       `gorm:"column:from_peer_id;not null"`
	Content      string    `gorm:"column:content;type:text"`
	CreatedAt    time.Time `gorm:"column:created_at;not null"`
}

func (chatMessageModel) TableName() string {
	return "messages"
}

func chatMessageModelToDomain(m *chatMessageModel) *domain.Message {
	if m == nil {
		return nil
	}

	return &domain.Message{
		Id:           m.Id,
		PeerType:     m.PeerType,
		PeerId:       m.PeerId,
		FromPeerType: m.FromPeerType,
		FromPeerId:   m.FromPeerId,
		Content:      m.Content,
		CreatedAt:    m.CreatedAt,
	}
}

func chatMessageDomainToModel(msg *domain.Message) *chatMessageModel {
	if msg == nil {
		return nil
	}

	return &chatMessageModel{
		Id:           msg.Id,
		PeerType:     msg.PeerType,
		PeerId:       msg.PeerId,
		FromPeerType: msg.FromPeerType,
		FromPeerId:   msg.FromPeerId,
		Content:      msg.Content,
		CreatedAt:    msg.CreatedAt,
	}
}
