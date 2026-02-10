package usecase

import (
	"context"
	"errors"
	"testing"

	"github.com/magomedcoder/legion/internal/config"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/service"
)

type mockUserRepoForUserUC struct {
	getByUsername func(context.Context, string) (*domain.User, error)
	list          func(context.Context, int32, int32) ([]*domain.User, int32, error)
	create        func(context.Context, *domain.User) error
}

func (m *mockUserRepoForUserUC) GetByUsername(ctx context.Context, username string) (*domain.User, error) {
	if m.getByUsername != nil {
		return m.getByUsername(ctx, username)
	}

	return nil, errors.New("не найдено")
}

func (m *mockUserRepoForUserUC) Create(ctx context.Context, user *domain.User) error {
	if m.create != nil {
		return m.create(ctx, user)
	}

	return nil
}

func (m *mockUserRepoForUserUC) GetById(context.Context, int) (*domain.User, error) {
	return nil, nil
}

func (m *mockUserRepoForUserUC) List(ctx context.Context, page, pageSize int32) ([]*domain.User, int32, error) {
	if m.list != nil {
		return m.list(ctx, page, pageSize)
	}

	return nil, 0, nil
}

func (m *mockUserRepoForUserUC) Update(context.Context, *domain.User) error {
	return nil
}

func (m *mockUserRepoForUserUC) UpdateLastVisitedAt(context.Context, int) error {
	return nil
}

func (m *mockUserRepoForUserUC) Search(context.Context, string, int32, int32) ([]*domain.User, int32, error) {
	return nil, 0, nil
}

type mockSessionRepoForUserUC struct{}

func (m *mockSessionRepoForUserUC) Create(context.Context, *domain.Token) error {
	return nil
}

func (m *mockSessionRepoForUserUC) GetByToken(context.Context, string) (*domain.Token, error) {
	return nil, errors.New("не найдено")
}

func (m *mockSessionRepoForUserUC) DeleteByToken(context.Context, string) error {
	return nil
}

func (m *mockSessionRepoForUserUC) DeleteByUserId(context.Context, int, domain.TokenType) error {
	return nil
}

func (m *mockSessionRepoForUserUC) CountByUserIdAndType(context.Context, int, domain.TokenType) (int, error) {
	return 0, nil
}

func (m *mockSessionRepoForUserUC) DeleteOldestByUserIdAndType(context.Context, int, domain.TokenType, int) error {
	return nil
}

func (m *mockSessionRepoForUserUC) ListByUserIdAndType(context.Context, int, domain.TokenType) ([]*domain.Token, error) {
	return nil, nil
}

func (m *mockSessionRepoForUserUC) DeleteByIdAndUserId(context.Context, int, int) error {
	return nil
}

func (m *mockSessionRepoForUserUC) DeleteRefreshTokensByUserIdExcept(context.Context, int, string) error {
	return nil
}

func TestUserUseCase_CreateUser_validation(t *testing.T) {
	cfg, _ := config.Load()
	jwtSvc := service.NewJWTService(cfg)
	userRepo := &mockUserRepoForUserUC{}
	uc := NewUserUseCase(userRepo, &mockSessionRepoForUserUC{}, jwtSvc)
	ctx := context.Background()

	_, err := uc.CreateUser(ctx, "", "password123", "", "", 0)
	if err == nil {
		t.Fatal("ожидалась ошибка при пустом username")
	}

	if err.Error() != "username и name обязательны" {
		t.Errorf("получено %q", err.Error())
	}

	_, err = uc.CreateUser(ctx, "test1", "test1", "Test1", "T", 0)
	if err == nil {
		t.Fatal("ожидалась ошибка при коротком пароле")
	}
}

func TestUserUseCase_GetUsers(t *testing.T) {
	users := []*domain.User{
		{
			Id:       1,
			Username: "u",
		},
	}
	userRepo := &mockUserRepoForUserUC{
		list: func(context.Context, int32, int32) ([]*domain.User, int32, error) {
			return users, 1, nil
		},
	}
	cfg, _ := config.Load()
	uc := NewUserUseCase(userRepo, &mockSessionRepoForUserUC{}, service.NewJWTService(cfg))
	got, total, err := uc.GetUsers(context.Background(), 1, 10)
	if err != nil {
		t.Fatalf("GetUsers: %v", err)
	}

	if total != 1 || len(got) != 1 || got[0].Username != "u" {
		t.Errorf("GetUsers: получено %v, total %d", got, total)
	}
}
