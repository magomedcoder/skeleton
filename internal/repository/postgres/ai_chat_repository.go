package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/pkg"
	"gorm.io/gorm"
)

type aiChatSessionRepository struct {
	db *gorm.DB
}

func NewAIChatSessionRepository(db *gorm.DB) domain.AIChatRepository {
	return &aiChatSessionRepository{db: db}
}

func (ai *aiChatSessionRepository) Create(ctx context.Context, session *domain.AIChatSession) error {
	m := aiChatSessionDomainToModel(session)
	if err := ai.db.WithContext(ctx).Create(m).Error; err != nil {
		return err
	}
	return nil
}

func (ai *aiChatSessionRepository) GetById(ctx context.Context, id string) (*domain.AIChatSession, error) {
	var m aiChatSessionModel
	err := ai.db.WithContext(ctx).Where("id = ?", id).First(&m).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, pkg.HandleNotFound(err, "сессия не найдена")
		}
		return nil, err
	}
	return aiChatSessionModelToDomain(&m), nil
}

func (ai *aiChatSessionRepository) GetByUserId(ctx context.Context, userID int, page, pageSize int32) ([]*domain.AIChatSession, int32, error) {
	_, pageSize, offset := normalizePagination(page, pageSize)

	var total int64
	if err := ai.db.WithContext(ctx).Model(&aiChatSessionModel{}).
		Where("user_id = ?", userID).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var list []aiChatSessionModel
	if err := ai.db.WithContext(ctx).Where("user_id = ?", userID).
		Order("created_at DESC").Limit(int(pageSize)).Offset(int(offset)).
		Find(&list).Error; err != nil {
		return nil, 0, err
	}

	sessions := make([]*domain.AIChatSession, 0, len(list))
	for i := range list {
		sessions = append(sessions, aiChatSessionModelToDomain(&list[i]))
	}
	return sessions, int32(total), nil
}

func (ai *aiChatSessionRepository) Update(ctx context.Context, session *domain.AIChatSession) error {
	session.UpdatedAt = time.Now()
	return ai.db.WithContext(ctx).Model(&aiChatSessionModel{}).
		Where("id = ?", session.Id).
		Updates(map[string]interface{}{
			"title":      session.Title,
			"model":      session.Model,
			"updated_at": session.UpdatedAt,
		}).Error
}

func (ai *aiChatSessionRepository) Delete(ctx context.Context, id string) error {
	return ai.db.WithContext(ctx).Delete(&aiChatSessionModel{}, id).Error
}
