package postgres

import (
	"time"

	"github.com/magomedcoder/skeleton/internal/domain"
	"gorm.io/gorm"
)

type userSessionModel struct {
	Id        int            `gorm:"column:id;primaryKey;autoIncrement"`
	UserId    int            `gorm:"column:user_id;not null;index"`
	Token     string         `gorm:"column:token;type:text;uniqueIndex;not null"`
	Type      string         `gorm:"column:type;size:20;not null"`
	ExpiresAt time.Time      `gorm:"column:expires_at;not null"`
	CreatedAt time.Time      `gorm:"column:created_at;not null"`
	DeletedAt gorm.DeletedAt `gorm:"column:deleted_at;index"`
}

func (userSessionModel) TableName() string {
	return "user_sessions"
}

func tokenModelToDomain(m *userSessionModel) *domain.Token {
	if m == nil {
		return nil
	}

	var deletedAt *time.Time
	if m.DeletedAt.Valid {
		t := m.DeletedAt.Time
		deletedAt = &t
	}

	return &domain.Token{
		Id:        m.Id,
		UserId:    m.UserId,
		Token:     m.Token,
		Type:      domain.TokenType(m.Type),
		ExpiresAt: m.ExpiresAt,
		CreatedAt: m.CreatedAt,
		DeletedAt: deletedAt,
	}
}

func tokenDomainToModel(t *domain.Token) *userSessionModel {
	if t == nil {
		return nil
	}

	var deletedAt gorm.DeletedAt
	if t.DeletedAt != nil {
		deletedAt = gorm.DeletedAt{Time: *t.DeletedAt, Valid: true}
	}

	return &userSessionModel{
		Id:        t.Id,
		UserId:    t.UserId,
		Token:     t.Token,
		Type:      string(t.Type),
		ExpiresAt: t.ExpiresAt,
		CreatedAt: t.CreatedAt,
		DeletedAt: deletedAt,
	}
}
