package postgres

import (
	"context"
	"strings"
	"testing"

	"github.com/magomedcoder/skeleton/internal/domain"
)

func TestNewDB_invalidDSN(t *testing.T) {
	ctx := context.Background()
	db, err := NewDB(ctx, "invalid-dsn-not-a-url")
	if err == nil {
		if db != nil {
			if sqlDB, _ := db.DB(); sqlDB != nil {
				_ = sqlDB.Close()
			}
		}
		t.Fatal("ожидалась ошибка при невалидном DSN")
	}

	if !strings.Contains(err.Error(), "ошибка") {
		t.Errorf("сообщение ошибки: %v", err)
	}
}

func TestNewDB_emptyDSN(t *testing.T) {
	ctx := context.Background()
	_, err := NewDB(ctx, "")
	if err == nil {
		t.Fatal("ожидалась ошибка при пустом DSN")
	}
}

func TestNewUserRepository_returnsImplementation(t *testing.T) {
	repo := NewUserRepository(nil)
	if repo == nil {
		t.Fatal("NewUserRepository не должен возвращать nil")
	}

	var _ domain.UserRepository = repo
}

func TestNewUserSessionRepository_returnsImplementation(t *testing.T) {
	repo := NewUserSessionRepository(nil)
	if repo == nil {
		t.Fatal("NewUserSessionRepository не должен возвращать nil")
	}

	var _ domain.UserSessionRepository = repo
}

func TestNewAIChatSessionRepository_returnsImplementation(t *testing.T) {
	repo := NewAIChatSessionRepository(nil)
	if repo == nil {
		t.Fatal("NewAIChatSessionRepository не должен возвращать nil")
	}

	var _ domain.AIChatRepository = repo
}

func TestNewMessageRepository_returnsImplementation(t *testing.T) {
	repo := NewMessageRepository(nil)
	if repo == nil {
		t.Fatal("NewMessageRepository не должен возвращать nil")
	}

	var _ domain.AIChatMessageRepository = repo
}

func TestNewFileRepository_returnsImplementation(t *testing.T) {
	repo := NewFileRepository(nil)
	if repo == nil {
		t.Fatal("NewFileRepository не должен возвращать nil")
	}

	var _ domain.FileRepository = repo
}
