package usecase

import (
	"context"
	"errors"
	"testing"

	"github.com/magomedcoder/legion/internal/domain"
)

type mockUserRepoForSearchUC struct {
	search func(context.Context, string, int32, int32) ([]*domain.User, int32, error)
}

func (m *mockUserRepoForSearchUC) Search(ctx context.Context, query string, page, pageSize int32) ([]*domain.User, int32, error) {
	if m.search != nil {
		return m.search(ctx, query, page, pageSize)
	}
	return nil, 0, nil
}

func (m *mockUserRepoForSearchUC) Create(context.Context, *domain.User) error {
	return nil
}

func (m *mockUserRepoForSearchUC) GetById(context.Context, int) (*domain.User, error) {
	return nil, nil
}

func (m *mockUserRepoForSearchUC) GetByUsername(context.Context, string) (*domain.User, error) {
	return nil, nil
}

func (m *mockUserRepoForSearchUC) List(context.Context, int32, int32) ([]*domain.User, int32, error) {
	return nil, 0, nil
}

func (m *mockUserRepoForSearchUC) Update(context.Context, *domain.User) error {
	return nil
}

func (m *mockUserRepoForSearchUC) UpdateLastVisitedAt(context.Context, int) error {
	return nil
}

func TestSearchUseCase_SearchUsers_emptyQuery_returnsEmpty(t *testing.T) {
	repo := &mockUserRepoForSearchUC{}
	uc := NewSearchUseCase(repo)
	ctx := context.Background()

	users, total, err := uc.SearchUsers(ctx, "", 0, 10)
	if err != nil {
		t.Fatalf("SearchUsers: %v", err)
	}

	if total != 0 || len(users) != 0 {
		t.Errorf("ожидались пустые users и total=0, получено total=%d len=%d", total, len(users))
	}
}

func TestSearchUseCase_SearchUsers_trimmedEmpty_returnsEmpty(t *testing.T) {
	repo := &mockUserRepoForSearchUC{}
	uc := NewSearchUseCase(repo)
	ctx := context.Background()

	users, total, err := uc.SearchUsers(ctx, "   \t  ", 0, 10)
	if err != nil {
		t.Fatalf("SearchUsers: %v", err)
	}

	if total != 0 || len(users) != 0 {
		t.Errorf("ожидались пустые users и total=0, получено total=%d len=%d", total, len(users))
	}
}

func TestSearchUseCase_SearchUsers_success(t *testing.T) {
	users := []*domain.User{
		{
			Id:       1,
			Username: "test1",
			Password: "secret",
			Name:     "Test1",
			Role:     domain.UserRoleUser,
		},
	}
	repo := &mockUserRepoForSearchUC{
		search: func(context.Context, string, int32, int32) ([]*domain.User, int32, error) {
			return users, 1, nil
		},
	}
	uc := NewSearchUseCase(repo)
	ctx := context.Background()

	got, total, err := uc.SearchUsers(ctx, "test1", 0, 10)
	if err != nil {
		t.Fatalf("SearchUsers: %v", err)
	}

	if total != 1 || len(got) != 1 {
		t.Errorf("ожидались total=1 и 1 user, получено total=%d len=%d", total, len(got))
	}

	if got[0].Username != "test1" || got[0].Password != "" {
		t.Errorf("ожидался user test1 с очищенным паролем, получено Username=%q Password=%q", got[0].Username, got[0].Password)
	}
}

func TestSearchUseCase_SearchUsers_repoError(t *testing.T) {
	repo := &mockUserRepoForSearchUC{
		search: func(context.Context, string, int32, int32) ([]*domain.User, int32, error) {
			return nil, 0, errors.New("db error")
		},
	}
	uc := NewSearchUseCase(repo)
	ctx := context.Background()

	_, _, err := uc.SearchUsers(ctx, "q", 0, 10)
	if err == nil {
		t.Fatal("ожидалась ошибка")
	}

	if err.Error() != "db error" {
		t.Errorf("получено %q", err.Error())
	}
}
