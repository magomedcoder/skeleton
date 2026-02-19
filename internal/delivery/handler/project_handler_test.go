package handler

import (
	"context"
	"testing"

	"github.com/magomedcoder/legion/api/pb/projectpb"
	"github.com/magomedcoder/legion/internal/delivery/middleware"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/usecase"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestProject_CreateProject_noAuth(t *testing.T) {
	h := NewProjectHandler(usecase.NewProjectUseCase(nil, nil, nil, nil, nil, nil, nil))
	ctx := context.Background()

	_, err := h.CreateProject(ctx, &projectpb.CreateProjectRequest{
		Name: "test",
	})
	if err == nil {
		t.Fatal("ожидалась ошибка без сессии")
	}
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("код = %v, ожидался Unauthenticated", code)
	}
}

func TestProject_CreateProject_emptyName(t *testing.T) {
	uc := usecase.NewProjectUseCase(
		&mockProjectRepoList{},
		&mockProjectMemberRepoList{},
		&mockProjectTaskRepoList{},
		&mockProjectTaskCommentRepoList{},
		&mockProjectColumnRepoList{},
		&mockProjectActivityRepoList{},
		&mockUserRepoList{},
	)
	h := NewProjectHandler(uc)
	ctx := context.WithValue(context.Background(), sessionKey, &middleware.JSession{
		Uid: 1,
	})

	_, err := h.CreateProject(ctx, &projectpb.CreateProjectRequest{
		Name: "",
	})
	if err == nil {
		t.Fatal("ожидалась ошибка при пустом названии")
	}
	if code := status.Code(err); code != codes.InvalidArgument {
		t.Errorf("код = %v, ожидался InvalidArgument", code)
	}
}

func TestProject_GetProjects_noAuth(t *testing.T) {
	h := NewProjectHandler(usecase.NewProjectUseCase(nil, nil, nil, nil, nil, nil, nil))
	ctx := context.Background()

	_, err := h.GetProjects(ctx, &projectpb.GetProjectsRequest{})
	if err == nil {
		t.Fatal("ожидалась ошибка без сессии")
	}
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("код = %v, ожидался Unauthenticated", code)
	}
}

type mockProjectRepoList struct{}

func (m *mockProjectRepoList) Create(ctx context.Context, project *domain.Project) error {
	return nil
}

func (m *mockProjectRepoList) GetById(ctx context.Context, id string) (*domain.Project, error) {
	return nil, nil
}

func (m *mockProjectRepoList) ListByUser(ctx context.Context, userId int, page, pageSize int32) ([]*domain.Project, int32, error) {
	return nil, 0, nil
}

type mockProjectMemberRepoList struct{}

func (m *mockProjectMemberRepoList) Add(ctx context.Context, projectId string, userId, createdBy int) error {
	return nil
}

func (m *mockProjectMemberRepoList) GetByProjectId(ctx context.Context, projectId string) ([]int, error) {
	return nil, nil
}

func (m *mockProjectMemberRepoList) IsMember(ctx context.Context, projectId string, userId int) (bool, error) {
	return false, nil
}

type mockProjectTaskRepoList struct{}

func (m *mockProjectTaskRepoList) Create(ctx context.Context, task *domain.Task) error {
	return nil
}

func (m *mockProjectTaskRepoList) GetById(ctx context.Context, id string) (*domain.Task, error) {
	return nil, nil
}

func (m *mockProjectTaskRepoList) ListByProjectId(ctx context.Context, projectId string) ([]*domain.Task, error) {
	return nil, nil
}

func (m *mockProjectTaskRepoList) EditColumnId(ctx context.Context, id, columnId string) error {
	return nil
}

func (m *mockProjectTaskRepoList) Edit(ctx context.Context, task *domain.Task) error { return nil }

type mockProjectTaskCommentRepoList struct{}

func (m *mockProjectTaskCommentRepoList) Create(ctx context.Context, comment *domain.TaskComment) error {
	return nil
}

func (m *mockProjectTaskCommentRepoList) ListByTaskId(ctx context.Context, taskId string) ([]*domain.TaskComment, error) {
	return nil, nil
}

type mockProjectColumnRepoList struct{}

func (m *mockProjectColumnRepoList) Create(ctx context.Context, col *domain.ProjectColumn) error {
	return nil
}

func (m *mockProjectColumnRepoList) GetById(ctx context.Context, id string) (*domain.ProjectColumn, error) {
	return nil, nil
}

func (m *mockProjectColumnRepoList) ListByProjectId(ctx context.Context, projectId string) ([]*domain.ProjectColumn, error) {
	return nil, nil
}

func (m *mockProjectColumnRepoList) Edit(ctx context.Context, col *domain.ProjectColumn) error {
	return nil
}

func (m *mockProjectColumnRepoList) Delete(ctx context.Context, id string) error {
	return nil
}

func (m *mockProjectColumnRepoList) ExistsStatusKey(ctx context.Context, projectId, statusKey, excludeId string) (bool, error) {
	return false, nil
}

type mockProjectActivityRepoList struct{}

func (m *mockProjectActivityRepoList) Create(ctx context.Context, a *domain.ProjectActivity) error {
	return nil
}

func (m *mockProjectActivityRepoList) ListByProjectId(ctx context.Context, projectId string, limit int) ([]*domain.ProjectActivity, error) {
	return nil, nil
}

func (m *mockProjectActivityRepoList) ListByTaskId(ctx context.Context, taskId string, limit int) ([]*domain.ProjectActivity, error) {
	return nil, nil
}

type mockUserRepoList struct{}

func (m *mockUserRepoList) Create(ctx context.Context, user *domain.User) error {
	return nil
}

func (m *mockUserRepoList) GetById(ctx context.Context, id int) (*domain.User, error) {
	return nil, nil
}

func (m *mockUserRepoList) GetByUsername(ctx context.Context, username string) (*domain.User, error) {
	return nil, nil
}

func (m *mockUserRepoList) List(ctx context.Context, page, pageSize int32) ([]*domain.User, int32, error) {
	return nil, 0, nil
}

func (m *mockUserRepoList) Search(ctx context.Context, query string, page, pageSize int32) ([]*domain.User, int32, error) {
	return nil, 0, nil
}

func (m *mockUserRepoList) Update(ctx context.Context, user *domain.User) error {
	return nil
}

func (m *mockUserRepoList) UpdateLastVisitedAt(ctx context.Context, userID int) error {
	return nil
}
