package postgres

import (
	"time"

	"github.com/magomedcoder/legion/internal/domain"
)

type chatMessageModel struct {
	Id         int64     `gorm:"column:id;primaryKey;autoIncrement"`
	ChatId     int       `gorm:"column:chat_id;not null;index"`
	ChatType   int       `gorm:"column:chat_type;not null;default:1"`
	UserId     int       `gorm:"column:user_id;not null;index"`
	ReceiverId int       `gorm:"column:receiver_id;not null;index"`
	Content    string    `gorm:"column:content;type:text"`
	CreatedAt  time.Time `gorm:"column:created_at;not null"`
}

func (chatMessageModel) TableName() string {
	return "messages"
}

func chatMessageModelToDomain(m *chatMessageModel) *domain.Message {
	if m == nil {
		return nil
	}

	return &domain.Message{
		Id:         m.Id,
		ChatId:     m.ChatId,
		ChatType:   m.ChatType,
		UserId:     m.UserId,
		ReceiverId: m.ReceiverId,
		Content:    m.Content,
		CreatedAt:  m.CreatedAt,
	}
}

func chatMessageDomainToModel(msg *domain.Message) *chatMessageModel {
	if msg == nil {
		return nil
	}

	return &chatMessageModel{
		Id:         msg.Id,
		ChatId:     msg.ChatId,
		ChatType:   msg.ChatType,
		UserId:     msg.UserId,
		ReceiverId: msg.ReceiverId,
		Content:    msg.Content,
		CreatedAt:  msg.CreatedAt,
	}
}
