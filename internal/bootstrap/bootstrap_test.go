package bootstrap

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/magomedcoder/legion/internal/config"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/service"
)

func TestCheckDatabase_invalidDSN(t *testing.T) {
	ctx := context.Background()
	err := CheckDatabase(ctx, "postgres://localhost/")
	if err == nil {
		t.Fatal("ожидалась ошибка при невалидном DSN")
	}

	if !strings.Contains(err.Error(), "имя базы данных не указано") {
		t.Errorf("сообщение ошибки: %v", err)
	}
}

func TestCheckDatabase_invalidURL(t *testing.T) {
	ctx := context.Background()
	err := CheckDatabase(ctx, "://invalid")
	if err == nil {
		t.Fatal("ожидалась ошибка при невалидном URL")
	}
}

type mockUserRepoBootstrap struct {
	list   func(context.Context, int32, int32) ([]*domain.User, int32, error)
	create func(context.Context, *domain.User) error
}

func (m *mockUserRepoBootstrap) List(ctx context.Context, page, pageSize int32) ([]*domain.User, int32, error) {
	if m.list != nil {
		return m.list(ctx, page, pageSize)
	}

	return nil, 0, nil
}

func (m *mockUserRepoBootstrap) Create(ctx context.Context, user *domain.User) error {
	if m.create != nil {
		return m.create(ctx, user)
	}

	return nil
}

func (m *mockUserRepoBootstrap) GetByUsername(context.Context, string) (*domain.User, error) {
	return nil, errors.New("не найдено")
}

func (m *mockUserRepoBootstrap) GetById(context.Context, int) (*domain.User, error) {
	return nil, errors.New("не найдено")
}

func (m *mockUserRepoBootstrap) Update(context.Context, *domain.User) error {
	return nil
}

func (m *mockUserRepoBootstrap) UpdateLastVisitedAt(context.Context, int) error {
	return nil
}

func (m *mockUserRepoBootstrap) Search(context.Context, string, int32, int32) ([]*domain.User, int32, error) {
	return nil, 0, nil
}

func TestCreateFirstUser_skipsWhenUsersExist(t *testing.T) {
	cfg, _ := config.Load()
	jwtSvc := service.NewJWTService(cfg)
	createCalled := false
	userRepo := &mockUserRepoBootstrap{
		list: func(context.Context, int32, int32) ([]*domain.User, int32, error) {
			return nil, 1, nil
		},
		create: func(context.Context, *domain.User) error {
			createCalled = true
			return nil
		},
	}

	ctx := context.Background()
	err := CreateFirstUser(ctx, userRepo, jwtSvc)
	if err != nil {
		t.Fatalf("CreateFirstUser: %v", err)
	}

	if createCalled {
		t.Error("Create не должен вызываться, когда пользователи уже есть")
	}
}

func TestCreateFirstUser_createsWhenNoUsers(t *testing.T) {
	cfg, _ := config.Load()
	jwtSvc := service.NewJWTService(cfg)
	var createdUser *domain.User
	userRepo := &mockUserRepoBootstrap{
		list: func(context.Context, int32, int32) ([]*domain.User, int32, error) {
			return nil, 0, nil
		},
		create: func(ctx context.Context, user *domain.User) error {
			createdUser = user
			return nil
		},
	}

	ctx := context.Background()
	err := CreateFirstUser(ctx, userRepo, jwtSvc)
	if err != nil {
		t.Fatalf("CreateFirstUser: %v", err)
	}

	if createdUser == nil {
		t.Fatal("ожидался вызов Create с пользователем")
	}

	if createdUser.Username != "legion" || createdUser.Role != domain.UserRoleAdmin {
		t.Errorf("создан пользователь: %+v", createdUser)
	}
}
