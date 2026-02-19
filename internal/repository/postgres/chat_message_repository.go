package postgres

import (
	"context"

	"github.com/magomedcoder/legion/internal/domain"
	"gorm.io/gorm"
)

type chatMessageRepository struct {
	db *gorm.DB
}

func NewChatMessageRepository(db *gorm.DB) domain.ChatMessageRepository {
	return &chatMessageRepository{db: db}
}

func (r *chatMessageRepository) Create(ctx context.Context, msg *domain.Message) error {
	m := chatMessageDomainToModel(msg)
	if err := r.db.WithContext(ctx).Create(m).Error; err != nil {
		return err
	}

	msg.Id = m.Id
	return nil
}

func (r *chatMessageRepository) GetById(ctx context.Context, id int64) (*domain.Message, error) {
	var m chatMessageModel
	if err := r.db.WithContext(ctx).Where("id = ?", id).First(&m).Error; err != nil {
		return nil, err
	}

	return chatMessageModelToDomain(&m), nil
}

func (r *chatMessageRepository) GetHistory(ctx context.Context, peerId1, peerId2 int, messageId int64, limit int) ([]*domain.Message, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}

	q := r.db.WithContext(ctx).Where("((peer_id = ? AND from_peer_id = ?) OR (peer_id = ? AND from_peer_id = ?))", peerId1, peerId2, peerId2, peerId1)
	if messageId > 0 {
		q = q.Where("id < ?", messageId)
	}
	var list []chatMessageModel
	if err := q.Order("id DESC").
		Limit(limit).
		Find(&list).Error; err != nil {
		return nil, err
	}

	for i, j := 0, len(list)-1; i < j; i, j = i+1, j-1 {
		list[i], list[j] = list[j], list[i]
	}

	msgs := make([]*domain.Message, 0, len(list))
	for i := range list {
		msgs = append(msgs, chatMessageModelToDomain(&list[i]))
	}
	return msgs, nil
}
