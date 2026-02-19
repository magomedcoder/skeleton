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

func (c *chatRepository) GetById(ctx context.Context, id int) (*domain.Chat, error) {
	var m chatModel
	if err := c.db.WithContext(ctx).First(&m, id).Error; err != nil {
		return nil, err
	}
	return chatModelToDomain(&m), nil
}

func (c *chatRepository) GetPrivateChat(ctx context.Context, uid, userId int) (*domain.Chat, error) {
	var m chatModel
	err := c.db.WithContext(ctx).
		Where("user_id = ? AND peer_type = ? AND peer_id = ?", uid, 1, userId).
		First(&m).Error
	if err != nil {
		return nil, err
	}

	return chatModelToDomain(&m), nil
}

func (c *chatRepository) GetOrCreatePrivateChat(ctx context.Context, uid, userId int) (*domain.Chat, error) {
	var m chatModel

	err := c.db.WithContext(ctx).
		Where("user_id = ? AND peer_type = ? AND peer_id = ?", uid, 1, userId).
		First(&m).Error

	if err == nil {
		return chatModelToDomain(&m), nil
	}

	if err != gorm.ErrRecordNotFound {
		return nil, err
	}

	newChat := &domain.Chat{
		PeerType: 1,
		PeerId:   userId,
		UserId:   uid,
	}
	mNew := chatDomainToModel(newChat)

	if err := c.db.WithContext(ctx).Create(mNew).Error; err != nil {
		return nil, err
	}

	return chatModelToDomain(mNew), nil
}

func (c *chatRepository) EnsurePeerChat(ctx context.Context, uid, peerUserId int) error {
	var m chatModel
	err := c.db.WithContext(ctx).
		Where("user_id = ? AND peer_type = ? AND peer_id = ?", peerUserId, 1, uid).
		First(&m).Error
	if err == nil {
		return nil
	}

	if err != gorm.ErrRecordNotFound {
		return err
	}

	peerChat := &domain.Chat{
		PeerType: 1,
		PeerId:   uid,
		UserId:   peerUserId,
	}
	
	return c.db.WithContext(ctx).Create(chatDomainToModel(peerChat)).Error
}

func (c *chatRepository) ListByUser(ctx context.Context, uid int) ([]*domain.Chat, error) {
	var list []chatModel
	if err := c.db.WithContext(ctx).
		Where("user_id = ?", uid).
		Order("updated_at DESC").
		Limit(200).
		Find(&list).Error; err != nil {
		return nil, err
	}

	chats := make([]*domain.Chat, 0, len(list))
	for i := range list {
		chats = append(chats, chatModelToDomain(&list[i]))
	}

	return chats, nil
}

func (c *chatRepository) GetAllUserIds(ctx context.Context, uid int) []int64 {
	var ids []int64
	c.db.WithContext(ctx).
		Model(&chatModel{}).
		Where("peer_type = ? AND user_id = ?", 1, uid).
		Pluck("peer_id", &ids)

	return ids
}
