package postgres

import (
	"context"

	"github.com/magomedcoder/legion/internal/domain"
	"gorm.io/gorm"
)

type chatRepository struct {
	db *gorm.DB
}

func NewChatRepository(db *gorm.DB) domain.ChatRepository {
	return &chatRepository{db: db}
}

func (r *chatRepository) GetById(ctx context.Context, id int) (*domain.Chat, error) {
	var m chatModel
	if err := r.db.WithContext(ctx).First(&m, id).Error; err != nil {
		return nil, err
	}
	return chatModelToDomain(&m), nil
}

func (r *chatRepository) GetOrCreatePrivateChat(ctx context.Context, uid, userId int) (*domain.Chat, error) {
	var m chatModel

	err := r.db.WithContext(ctx).
		Where("(user_id = ? AND receiver_id = ?) OR (user_id = ? AND receiver_id = ?)", uid, userId, userId, uid).
		First(&m).Error

	if err == nil {
		return chatModelToDomain(&m), nil
	}

	if err != gorm.ErrRecordNotFound {
		return nil, err
	}

	newChat := &domain.Chat{
		ChatType:   1,
		UserId:     uid,
		ReceiverId: userId,
	}
	mNew := chatDomainToModel(newChat)

	if err := r.db.WithContext(ctx).Create(mNew).Error; err != nil {
		return nil, err
	}

	return chatModelToDomain(mNew), nil
}

func (r *chatRepository) ListByUser(ctx context.Context, uid int, page, pageSize int32) ([]*domain.Chat, int32, error) {
	page, pageSize, offset := normalizePagination(page, pageSize)

	var total int64
	if err := r.db.WithContext(ctx).
		Model(&chatModel{}).
		Where("user_id = ? OR receiver_id = ?", uid, uid).
		Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var list []chatModel
	if err := r.db.WithContext(ctx).
		Where("user_id = ? OR receiver_id = ?", uid, uid).
		Order("created_at DESC").
		Limit(int(pageSize)).
		Offset(int(offset)).
		Find(&list).Error; err != nil {
		return nil, 0, err
	}

	chats := make([]*domain.Chat, 0, len(list))
	for i := range list {
		chats = append(chats, chatModelToDomain(&list[i]))
	}

	return chats, int32(total), nil
}
