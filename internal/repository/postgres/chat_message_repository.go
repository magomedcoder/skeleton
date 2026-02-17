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

func (r *chatMessageRepository) ListByChatId(ctx context.Context, chatId int, page, pageSize int32) ([]*domain.Message, int32, error) {
	page, pageSize, offset := normalizePagination(page, pageSize)

	var total int64
	if err := r.db.WithContext(ctx).
		Model(&chatMessageModel{}).
		Where("chat_id = ?", chatId).
		Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var list []chatMessageModel
	if err := r.db.WithContext(ctx).
		Where("chat_id = ?", chatId).
		Order("created_at ASC").
		Limit(int(pageSize)).
		Offset(int(offset)).
		Find(&list).Error; err != nil {
		return nil, 0, err
	}

	msgs := make([]*domain.Message, 0, len(list))
	for i := range list {
		msgs = append(msgs, chatMessageModelToDomain(&list[i]))
	}

	return msgs, int32(total), nil
}
