package handler

import (
	"context"
	"errors"
	"testing"

	"github.com/magomedcoder/legion/api/pb/searchpb"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/usecase"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type mockUserRepoForSearch struct {
	search func(context.Context, string, int32, int32) ([]*domain.User, int32, error)
}

func (m *mockUserRepoForSearch) Search(ctx context.Context, query string, page, pageSize int32) ([]*domain.User, int32, error) {
	if m.search != nil {
		return m.search(ctx, query, page, pageSize)
	}

	return nil, 0, nil
}

func (m *mockUserRepoForSearch) Create(context.Context, *domain.User) error {
	return nil
}

func (m *mockUserRepoForSearch) GetById(context.Context, int) (*domain.User, error) {
	return nil, nil
}

func (m *mockUserRepoForSearch) GetByUsername(context.Context, string) (*domain.User, error) {
	return nil, nil
}

func (m *mockUserRepoForSearch) List(context.Context, int32, int32) ([]*domain.User, int32, error) {
	return nil, 0, nil
}

func (m *mockUserRepoForSearch) Update(context.Context, *domain.User) error {
	return nil
}

func (m *mockUserRepoForSearch) UpdateLastVisitedAt(context.Context, int) error {
	return nil
}

func TestSearchHandler_Users_success(t *testing.T) {
	users := []*domain.User{
		{
			Id:       1,
			Username: "test1",
			Name:     "Test1",
			Surname:  "A",
			Role:     domain.UserRoleUser,
		},
	}
	repo := &mockUserRepoForSearch{
		search: func(context.Context, string, int32, int32) ([]*domain.User, int32, error) {
			return users, 1, nil
		},
	}
	uc := usecase.NewSearchUseCase(repo)
	h := NewSearchHandler(uc, nil)
	ctx := context.Background()

	resp, err := h.Users(ctx, &searchpb.SearchUsersRequest{
		Query:    "test1",
		Page:     0,
		PageSize: 10,
	})
	if err != nil {
		t.Fatalf("Users: %v", err)
	}

	if resp == nil {
		t.Fatal("ожидался непустой ответ")
	}

	if resp.Total != 1 || len(resp.Users) != 1 {
		t.Errorf("ожидались total=1 и 1 user, получено total=%d len(users)=%d", resp.Total, len(resp.Users))
	}

	if resp.Users[0].Username != "test1" || resp.Users[0].Name != "Test1" {
		t.Errorf("ожидался user test1/Test1, получено %v", resp.Users[0])
	}
}

func TestSearchHandler_Users_emptyQuery_returnsEmpty(t *testing.T) {
	repo := &mockUserRepoForSearch{}
	uc := usecase.NewSearchUseCase(repo)
	h := NewSearchHandler(uc, nil)
	ctx := context.Background()

	resp, err := h.Users(ctx, &searchpb.SearchUsersRequest{
		Query:    "   ",
		Page:     0,
		PageSize: 10,
	})
	if err != nil {
		t.Fatalf("Users(пустой query): %v", err)
	}

	if resp.Total != 0 || len(resp.Users) != 0 {
		t.Errorf("ожидались пустые users и total=0, получено total=%d len(users)=%d", resp.Total, len(resp.Users))
	}
}

func TestSearchHandler_Users_useCaseError_returnsInternal(t *testing.T) {
	repo := &mockUserRepoForSearch{
		search: func(context.Context, string, int32, int32) ([]*domain.User, int32, error) {
			return nil, 0, errors.New("db error")
		},
	}

	uc := usecase.NewSearchUseCase(repo)
	h := NewSearchHandler(uc, nil)
	ctx := context.Background()

	_, err := h.Users(ctx, &searchpb.SearchUsersRequest{
		Query:    "x",
		Page:     0,
		PageSize: 10,
	})
	if err == nil {
		t.Fatal("ожидалась ошибка")
	}
	if code := status.Code(err); code != codes.Internal {
		t.Errorf("ожидался код Internal, получен %v", code)
	}
}
