package postgres

import (
	"testing"
	"time"

	"github.com/magomedcoder/skeleton/internal/domain"
	"gorm.io/gorm"
)

func Test_tokenModelToDomain(t *testing.T) {
	now := time.Now()

	t.Run("nil возвращает nil", func(t *testing.T) {
		if got := tokenModelToDomain(nil); got != nil {
			t.Errorf("tokenModelToDomain(nil) = %v, ожидалось nil", got)
		}
	})

	t.Run("без DeletedAt", func(t *testing.T) {
		m := &userSessionModel{
			Id:        1,
			UserId:    10,
			Token:     "t",
			Type:      "access",
			ExpiresAt: now,
			CreatedAt: now,
		}
		got := tokenModelToDomain(m)
		if got == nil || got.Id != 1 || got.Token != "t" || got.DeletedAt != nil {
			t.Errorf("tokenModelToDomain: %+v", got)
		}
	})

	t.Run("с DeletedAt", func(t *testing.T) {
		m := &userSessionModel{Id: 2, DeletedAt: gorm.DeletedAt{
			Time:  now,
			Valid: true,
		}}
		got := tokenModelToDomain(m)
		if got == nil || got.DeletedAt == nil || !got.DeletedAt.Equal(now) {
			t.Errorf("tokenModelToDomain с DeletedAt: %+v", got)
		}
	})
}

func Test_tokenDomainToModel(t *testing.T) {
	now := time.Now()

	t.Run("nil возвращает nil", func(t *testing.T) {
		if got := tokenDomainToModel(nil); got != nil {
			t.Errorf("tokenDomainToModel(nil) = %v, ожидалось nil", got)
		}
	})

	t.Run("с DeletedAt", func(t *testing.T) {
		tok := &domain.Token{
			Id:        1,
			UserId:    10,
			Token:     "t",
			Type:      domain.TokenTypeAccess,
			ExpiresAt: now,
			CreatedAt: now,
			DeletedAt: &now,
		}
		got := tokenDomainToModel(tok)
		if got == nil || !got.DeletedAt.Valid || !got.DeletedAt.Time.Equal(now) {
			t.Errorf("tokenDomainToModel с DeletedAt: %+v", got)
		}
	})
}
