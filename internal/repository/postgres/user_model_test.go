package postgres

import (
	"testing"
	"time"

	"github.com/magomedcoder/legion/internal/domain"
	"gorm.io/gorm"
)

func Test_userModelToDomain(t *testing.T) {
	now := time.Now()

	t.Run("nil возвращает nil", func(t *testing.T) {
		if got := userModelToDomain(nil); got != nil {
			t.Errorf("userModelToDomain(nil) = %v, ожидалось nil", got)
		}
	})

	t.Run("без DeletedAt", func(t *testing.T) {
		m := &userModel{
			Id:        1,
			Username:  "t",
			Password:  "e",
			Name:      "s",
			Surname:   "t",
			Role:      0,
			CreatedAt: now,
		}
		got := userModelToDomain(m)
		if got == nil || got.Id != 1 || got.Username != "t" || got.DeletedAt != nil {
			t.Errorf("userModelToDomain: %+v", got)
		}
	})

	t.Run("с DeletedAt", func(t *testing.T) {
		m := &userModel{
			Id:       2,
			Username: "t2",
			DeletedAt: gorm.DeletedAt{
				Time:  now,
				Valid: true,
			},
		}
		got := userModelToDomain(m)
		if got == nil || got.DeletedAt == nil || !got.DeletedAt.Equal(now) {
			t.Errorf("userModelToDomain с DeletedAt: %+v", got)
		}
	})
}

func Test_userDomainToModel(t *testing.T) {
	now := time.Now()

	t.Run("nil возвращает nil", func(t *testing.T) {
		if got := userDomainToModel(nil); got != nil {
			t.Errorf("userDomainToModel(nil) = %v, ожидалось nil", got)
		}
	})

	t.Run("без DeletedAt", func(t *testing.T) {
		u := &domain.User{
			Id:        1,
			Username:  "t",
			Role:      domain.UserRoleUser,
			CreatedAt: now,
		}
		got := userDomainToModel(u)
		if got == nil || got.Id != 1 || got.Username != "t" || got.DeletedAt.Valid {
			t.Errorf("userDomainToModel: %+v", got)
		}
	})

	t.Run("с DeletedAt", func(t *testing.T) {
		u := &domain.User{
			Id:        2,
			Username:  "t2",
			DeletedAt: &now,
		}
		got := userDomainToModel(u)
		if got == nil || !got.DeletedAt.Valid || !got.DeletedAt.Time.Equal(now) {
			t.Errorf("userDomainToModel с DeletedAt: %+v", got)
		}
	})
}
