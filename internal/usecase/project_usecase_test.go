package usecase

import (
	"context"
	"testing"

	"github.com/magomedcoder/legion/internal/domain"
)

type mockProjectRepo struct {
	listByUser func(context.Context, int, int32, int32) ([]*domain.Project, int32, error)
}

func (m *mockProjectRepo) Create(ctx context.Context, project *domain.Project) error {
	return nil
}

func (m *mockProjectRepo) GetById(ctx context.Context, id string) (*domain.Project, error) {
	return nil, nil
}
func (m *mockProjectRepo) ListByUser(ctx context.Context, userId int, page, pageSize int32) ([]*domain.Project, int32, error) {
	if m.listByUser != nil {
		return m.listByUser(ctx, userId, page, pageSize)
	}

	return nil, 0, nil
}

type mockProjectMemberRepo struct{}
type mockProjectTaskRepo struct{}
type mockProjectTaskCommentRepo struct{}
type mockProjectColumnRepo struct{}
type mockProjectActivityRepo struct{}
type mockUserRepoProject struct{}

func (m *mockProjectMemberRepo) Add(ctx context.Context, projectId string, userId, createdBy int) error {
	return nil
}

func (m *mockProjectMemberRepo) GetByProjectId(ctx context.Context, projectId string) ([]int, error) {
	return nil, nil
}

func (m *mockProjectMemberRepo) IsMember(ctx context.Context, projectId string, userId int) (bool, error) {
	return false, nil
}

func (m *mockProjectTaskRepo) Create(ctx context.Context, task *domain.Task) error {
	return nil
}

func (m *mockProjectTaskRepo) GetById(ctx context.Context, id string) (*domain.Task, error) {
	return nil, nil
}

func (m *mockProjectTaskRepo) ListByProjectId(ctx context.Context, projectId string) ([]*domain.Task, error) {
	return nil, nil
}

func (m *mockProjectTaskRepo) EditColumnId(ctx context.Context, id, columnId string) error {
	return nil
}

func (m *mockProjectTaskRepo) Edit(ctx context.Context, task *domain.Task) error {
	return nil
}

func (m *mockProjectTaskCommentRepo) Create(ctx context.Context, comment *domain.TaskComment) error {
	return nil
}

func (m *mockProjectTaskCommentRepo) ListByTaskId(ctx context.Context, taskId string) ([]*domain.TaskComment, error) {
	return nil, nil
}

func (m *mockProjectColumnRepo) Create(ctx context.Context, col *domain.ProjectColumn) error {
	return nil
}

func (m *mockProjectColumnRepo) GetById(ctx context.Context, id string) (*domain.ProjectColumn, error) {
	return nil, nil
}

func (m *mockProjectColumnRepo) ListByProjectId(ctx context.Context, projectId string) ([]*domain.ProjectColumn, error) {
	return nil, nil
}

func (m *mockProjectColumnRepo) Edit(ctx context.Context, col *domain.ProjectColumn) error {
	return nil
}

func (m *mockProjectColumnRepo) Delete(ctx context.Context, id string) error {
	return nil
}

func (m *mockProjectColumnRepo) ExistsStatusKey(ctx context.Context, projectId, statusKey, excludeId string) (bool, error) {
	return false, nil
}

func (m *mockProjectActivityRepo) Create(ctx context.Context, a *domain.ProjectActivity) error {
	return nil
}

func (m *mockProjectActivityRepo) ListByProjectId(ctx context.Context, projectId string, limit int) ([]*domain.ProjectActivity, error) {
	return nil, nil
}

func (m *mockProjectActivityRepo) ListByTaskId(ctx context.Context, taskId string, limit int) ([]*domain.ProjectActivity, error) {
	return nil, nil
}

func (m *mockUserRepoProject) Create(ctx context.Context, user *domain.User) error {
	return nil
}

func (m *mockUserRepoProject) GetById(ctx context.Context, id int) (*domain.User, error) {
	return nil, nil
}

func (m *mockUserRepoProject) GetByUsername(ctx context.Context, username string) (*domain.User, error) {
	return nil, nil
}

func (m *mockUserRepoProject) List(ctx context.Context, page, pageSize int32) ([]*domain.User, int32, error) {
	return nil, 0, nil
}

func (m *mockUserRepoProject) Search(ctx context.Context, query string, page, pageSize int32) ([]*domain.User, int32, error) {
	return nil, 0, nil
}

func (m *mockUserRepoProject) Update(ctx context.Context, user *domain.User) error {
	return nil
}

func (m *mockUserRepoProject) UpdateLastVisitedAt(ctx context.Context, userID int) error {
	return nil
}

func TestProjectUseCase_CreateProject_emptyName(t *testing.T) {
	uc := NewProjectUseCase(
		&mockProjectRepo{},
		&mockProjectMemberRepo{},
		&mockProjectTaskRepo{},
		&mockProjectTaskCommentRepo{},
		&mockProjectColumnRepo{},
		&mockProjectActivityRepo{},
		&mockUserRepoProject{},
	)
	ctx := context.Background()

	_, err := uc.CreateProject(ctx, "", 1)
	if err == nil {
		t.Fatal("ожидалась ошибка при пустом названии")
	}
	if err.Error() != "название проекта обязательно" {
		t.Errorf("ошибка = %v", err)
	}
}

func TestProjectUseCase_GetProjects(t *testing.T) {
	wantList := []*domain.Project{{Id: "p1", Name: "Proj1"}}
	wantTotal := int32(1)
	uc := NewProjectUseCase(
		&mockProjectRepo{
			listByUser: func(ctx context.Context, userId int, page, pageSize int32) ([]*domain.Project, int32, error) {
				return wantList, wantTotal, nil
			},
		},
		&mockProjectMemberRepo{},
		&mockProjectTaskRepo{},
		&mockProjectTaskCommentRepo{},
		&mockProjectColumnRepo{},
		&mockProjectActivityRepo{},
		&mockUserRepoProject{},
	)
	ctx := context.Background()

	list, total, err := uc.GetProjects(ctx, 1, 1, 10)
	if err != nil {
		t.Fatalf("GetProjects: %v", err)
	}

	if total != wantTotal || len(list) != len(wantList) {
		t.Errorf("GetProjects: list=%v total=%d", list, total)
	}

	if len(list) > 0 && list[0].Id != wantList[0].Id {
		t.Errorf("GetProjects: list[0].Id = %s", list[0].Id)
	}
}
