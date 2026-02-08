package postgres

import (
	"context"

	"github.com/magomedcoder/skeleton/internal/domain"
	"gorm.io/gorm"
)

type messageRepository struct {
	db *gorm.DB
}

func NewMessageRepository(db *gorm.DB) domain.AIChatMessageRepository {
	return &messageRepository{db: db}
}

func (r *messageRepository) Create(ctx context.Context, message *domain.AIChatMessage) error {
	m := aiChatMessageDomainToModel(message)
	if err := r.db.WithContext(ctx).Create(m).Error; err != nil {
		return err
	}

	return nil
}

func (r *messageRepository) GetBySessionId(ctx context.Context, sessionID string, page, pageSize int32) ([]*domain.AIChatMessage, int32, error) {
	_, pageSize, offset := normalizePagination(page, pageSize)

	var total int64
	if err := r.db.WithContext(ctx).Model(&aiChatMessageModel{}).
		Where("session_id = ?", sessionID).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var list []aiChatMessageModel
	if err := r.db.WithContext(ctx).Where("session_id = ?", sessionID).
		Order("created_at ASC").Limit(int(pageSize)).Offset(int(offset)).
		Find(&list).Error; err != nil {
		return nil, 0, err
	}

	messages := make([]*domain.AIChatMessage, 0, len(list))
	for i := range list {
		messages = append(messages, aiChatMessageModelToDomain(&list[i]))
	}

	return messages, int32(total), nil
}
