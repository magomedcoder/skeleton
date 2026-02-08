package postgres

import (
	"testing"
	"time"

	"github.com/magomedcoder/skeleton/internal/domain"
	"gorm.io/gorm"
)

func Test_aiChatSessionModelToDomain(t *testing.T) {
	now := time.Now()

	t.Run("nil возвращает nil", func(t *testing.T) {
		if got := aiChatSessionModelToDomain(nil); got != nil {
			t.Errorf("aiChatSessionModelToDomain(nil) = %v, ожидалось nil", got)
		}
	})

	t.Run("с DeletedAt", func(t *testing.T) {
		m := &aiChatSessionModel{
			Id:        "uuid",
			UserId:    1,
			Title:     "t",
			Model:     "m",
			CreatedAt: now,
			UpdatedAt: now,
			DeletedAt: gorm.DeletedAt{
				Time:  now,
				Valid: true,
			},
		}
		got := aiChatSessionModelToDomain(m)
		if got == nil || got.DeletedAt == nil || !got.DeletedAt.Equal(now) {
			t.Errorf("aiChatSessionModelToDomain: %+v", got)
		}
	})
}

func Test_aiChatSessionDomainToModel(t *testing.T) {
	now := time.Now()

	t.Run("nil возвращает nil", func(t *testing.T) {
		if got := aiChatSessionDomainToModel(nil); got != nil {
			t.Errorf("aiChatSessionDomainToModel(nil) = %v, ожидалось nil", got)
		}
	})

	t.Run("с DeletedAt", func(t *testing.T) {
		s := &domain.AIChatSession{
			Id:        "uuid",
			UserId:    1,
			Title:     "t",
			Model:     "m",
			CreatedAt: now,
			UpdatedAt: now,
			DeletedAt: &now,
		}
		got := aiChatSessionDomainToModel(s)
		if got == nil || !got.DeletedAt.Valid || !got.DeletedAt.Time.Equal(now) {
			t.Errorf("aiChatSessionDomainToModel: %+v", got)
		}
	})
}
