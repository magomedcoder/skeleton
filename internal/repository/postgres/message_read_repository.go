package postgres

import (
	"context"

	"github.com/magomedcoder/legion/internal/domain"
	"gorm.io/gorm"
)

type messageReadModel struct {
	UserId            int    `gorm:"column:user_id;primaryKey"`
	PeerId            int    `gorm:"column:peer_id;primaryKey"`
	LastReadMessageId int64  `gorm:"column:last_read_message_id;not null"`
	UpdatedAt         string `gorm:"column:updated_at;not null"`
}

func (messageReadModel) TableName() string {
	return "message_read"
}

type messageReadRepository struct {
	db *gorm.DB
}

func NewMessageReadRepository(db *gorm.DB) domain.MessageReadRepository {
	return &messageReadRepository{db: db}
}

func (r *messageReadRepository) SetLastRead(ctx context.Context, userId, peerId int, messageId int64) error {
	return r.db.WithContext(ctx).Exec(`
		INSERT INTO message_read (user_id, peer_id, last_read_message_id, updated_at)
		VALUES (?, ?, ?, NOW())
		ON CONFLICT (user_id, peer_id)
		DO UPDATE SET last_read_message_id = GREATEST(message_read.last_read_message_id, ?), updated_at = NOW()`, userId, peerId, messageId, messageId,
	).Error
}

func (r *messageReadRepository) GetLastRead(ctx context.Context, userId, peerId int) (int64, error) {
	var id int64
	err := r.db.WithContext(ctx).Raw(`
		SELECT last_read_message_id
		FROM message_read
		WHERE user_id = ? AND peer_id = ?
	`, userId, peerId,
	).Scan(&id).Error
	if err != nil && err != gorm.ErrRecordNotFound {
		return 0, err
	}

	return id, nil
}

func (r *messageReadRepository) GetUnreadCount(ctx context.Context, userId, peerId int) (int, error) {
	var count int64
	err := r.db.WithContext(ctx).Raw(`
		SELECT COUNT(*) FROM messages m
		WHERE m.peer_id = ? AND m.from_peer_id = ? AND m.deleted_at IS NULL
		AND m.id > COALESCE((SELECT last_read_message_id FROM message_read WHERE user_id = ? AND peer_id = ?), 0)
	`, userId, peerId, userId, peerId,
	).Scan(&count).Error
	if err != nil {
		return 0, err
	}

	return int(count), nil
}
