package postgres

import (
	"context"

	"github.com/magomedcoder/legion/internal/domain"
	"gorm.io/gorm"
)

type userDeletedMessageModel struct {
	UserId    int   `gorm:"column:user_id;primaryKey"`
	MessageId int64 `gorm:"column:message_id;primaryKey"`
}

func (userDeletedMessageModel) TableName() string {
	return "user_deleted_messages"
}

type userDeletedMessageRepository struct {
	db *gorm.DB
}

func NewUserDeletedMessageRepository(db *gorm.DB) domain.UserDeletedMessageRepository {
	return &userDeletedMessageRepository{db: db}
}

func (r *userDeletedMessageRepository) Add(ctx context.Context, userId int, messageIds []int64) error {
	if len(messageIds) == 0 {
		return nil
	}

	for _, id := range messageIds {
		err := r.db.WithContext(ctx).Exec(`
			INSERT INTO user_deleted_messages (user_id, message_id) 
			VALUES (?, ?) ON CONFLICT (user_id, message_id) DO NOTHING
		`, userId, id,
		).Error
		if err != nil {
			return err
		}
	}

	return nil
}

func (r *userDeletedMessageRepository) GetDeletedMessageIds(ctx context.Context, userId int, messageIds []int64) ([]int64, error) {
	if len(messageIds) == 0 {
		return nil, nil
	}

	var ids []int64
	err := r.db.WithContext(ctx).Model(&userDeletedMessageModel{}).
		Where("user_id = ? AND message_id IN ?", userId, messageIds).
		Pluck("message_id", &ids).Error

	return ids, err
}
