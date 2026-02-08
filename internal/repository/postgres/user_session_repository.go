package postgres

import (
	"context"
	"errors"

	"github.com/magomedcoder/skeleton/internal/domain"
	"github.com/magomedcoder/skeleton/pkg"
	"gorm.io/gorm"
)

type userSessionRepository struct {
	db *gorm.DB
}

func NewUserSessionRepository(db *gorm.DB) domain.UserSessionRepository {
	return &userSessionRepository{db: db}
}

func (u *userSessionRepository) Create(ctx context.Context, token *domain.Token) error {
	m := tokenDomainToModel(token)
	if err := u.db.WithContext(ctx).Create(m).Error; err != nil {
		return err
	}
	token.Id = m.Id
	return nil
}

func (u *userSessionRepository) GetByToken(ctx context.Context, token string) (*domain.Token, error) {
	var m userSessionModel
	err := u.db.WithContext(ctx).Where("token = ?", token).First(&m).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, pkg.HandleNotFound(err, "токен не найден")
		}

		return nil, err
	}
	return tokenModelToDomain(&m), nil
}

func (u *userSessionRepository) DeleteByToken(ctx context.Context, token string) error {
	return u.db.WithContext(ctx).Where("token = ?", token).Delete(&userSessionModel{}).Error
}

func (u *userSessionRepository) DeleteByUserId(ctx context.Context, userID int, tokenType domain.TokenType) error {
	return u.db.WithContext(ctx).Where("user_id = ? AND type = ?", userID, tokenType).Delete(&userSessionModel{}).Error
}

func (u *userSessionRepository) CountByUserIdAndType(ctx context.Context, userID int, tokenType domain.TokenType) (int, error) {
	var count int64
	err := u.db.WithContext(ctx).Model(&userSessionModel{}).
		Where("user_id = ? AND type = ?", userID, tokenType).
		Count(&count).Error

	return int(count), err
}

func (u *userSessionRepository) DeleteOldestByUserIdAndType(ctx context.Context, userID int, tokenType domain.TokenType, limit int) error {
	if limit <= 0 {
		return nil
	}

	var ids []int
	if err := u.db.WithContext(ctx).Model(&userSessionModel{}).
		Where("user_id = ? AND type = ?", userID, tokenType).
		Order("created_at ASC").Limit(limit).Pluck("id", &ids).Error; err != nil {
		return err
	}
	if len(ids) == 0 {
		return nil
	}

	return u.db.WithContext(ctx).Delete(&userSessionModel{}, ids).Error
}

func (u *userSessionRepository) ListByUserIdAndType(ctx context.Context, userID int, tokenType domain.TokenType) ([]*domain.Token, error) {
	var list []userSessionModel
	if err := u.db.WithContext(ctx).
		Where("user_id = ? AND type = ?", userID, tokenType).
		Order("created_at DESC").Find(&list).Error; err != nil {
		return nil, err
	}
	tokens := make([]*domain.Token, 0, len(list))
	for i := range list {
		tokens = append(tokens, tokenModelToDomain(&list[i]))
	}

	return tokens, nil
}

func (u *userSessionRepository) DeleteByIdAndUserId(ctx context.Context, id, userID int) error {
	result := u.db.WithContext(ctx).Where("id = ? AND user_id = ?", id, userID).Delete(&userSessionModel{})
	if result.Error != nil {
		return result.Error
	}

	if result.RowsAffected == 0 {
		return errors.New("сессия не найдена")
	}

	return nil
}

func (u *userSessionRepository) DeleteRefreshTokensByUserIdExcept(ctx context.Context, userID int, keepRefreshToken string) error {
	return u.db.WithContext(ctx).
		Where("user_id = ? AND type = ? AND token != ?", userID, domain.TokenTypeRefresh, keepRefreshToken).
		Delete(&userSessionModel{}).Error
}
