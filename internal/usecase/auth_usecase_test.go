package usecase

import (
	"context"
	"errors"
	"testing"

	"github.com/magomedcoder/legion/internal/config"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/service"
)

type mockUserRepo struct {
	getByUsername func(context.Context, string) (*domain.User, error)
}

func (m *mockUserRepo) GetByUsername(ctx context.Context, username string) (*domain.User, error) {
	if m.getByUsername != nil {
		return m.getByUsername(ctx, username)
	}

	return nil, errors.New("не найдено")
}

func (m *mockUserRepo) Create(context.Context, *domain.User) error {
	return nil
}

func (m *mockUserRepo) GetById(context.Context, int) (*domain.User, error) {
	return nil, errors.New("не найдено")
}

func (m *mockUserRepo) List(context.Context, int32, int32) ([]*domain.User, int32, error) {
	return nil, 0, nil
}

func (m *mockUserRepo) Update(context.Context, *domain.User) error {
	return nil
}

func (m *mockUserRepo) UpdateLastVisitedAt(context.Context, int) error {
	return nil
}

func (m *mockUserRepo) Search(context.Context, string, int32, int32) ([]*domain.User, int32, error) {
	return nil, 0, nil
}

type mockUserSessionRepo struct{}

func (m *mockUserSessionRepo) Create(context.Context, *domain.Token) error {
	return nil
}

func (m *mockUserSessionRepo) GetByToken(context.Context, string) (*domain.Token, error) {
	return nil, errors.New("не найдено")
}

func (m *mockUserSessionRepo) DeleteByToken(context.Context, string) error {
	return nil
}

func (m *mockUserSessionRepo) DeleteByUserId(context.Context, int, domain.TokenType) error {
	return nil
}

func (m *mockUserSessionRepo) CountByUserIdAndType(context.Context, int, domain.TokenType) (int, error) {
	return 0, nil
}

func (m *mockUserSessionRepo) DeleteOldestByUserIdAndType(context.Context, int, domain.TokenType, int) error {
	return nil
}

func (m *mockUserSessionRepo) ListByUserIdAndType(context.Context, int, domain.TokenType) ([]*domain.Token, error) {
	return nil, nil
}

func (m *mockUserSessionRepo) DeleteByIdAndUserId(context.Context, int, int) error {
	return nil
}

func (m *mockUserSessionRepo) DeleteRefreshTokensByUserIdExcept(context.Context, int, string) error {
	return nil
}

func TestAuthUseCase_Login_userNotFound(t *testing.T) {
	userRepo := &mockUserRepo{}
	cfg, _ := config.Load()
	jwtSvc := service.NewJWTService(cfg)
	uc := NewAuthUseCase(userRepo, &mockUserSessionRepo{}, jwtSvc)

	_, _, _, err := uc.Login(context.Background(), "test1", "test1")
	if err == nil {
		t.Fatal("ожидалась ошибка при отсутствии пользователя")
	}

	if err.Error() != "неверные учетные данные" {
		t.Errorf("получено %q", err.Error())
	}
}
