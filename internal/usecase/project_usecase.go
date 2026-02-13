package usecase

import (
	"context"
	"errors"

	"github.com/magomedcoder/legion/internal/domain"
)

type ProjectUseCase struct {
	ProjectRepo       domain.ProjectRepository
	ProjectMemberRepo domain.ProjectMemberRepository
	TaskRepo          domain.TaskRepository
	UserRepo          domain.UserRepository
}

func NewProjectUseCase(
	projectRepo domain.ProjectRepository,
	projectMemberRepo domain.ProjectMemberRepository,
	taskRepo domain.TaskRepository,
	userRepo domain.UserRepository,
) *ProjectUseCase {
	return &ProjectUseCase{
		ProjectRepo:       projectRepo,
		ProjectMemberRepo: projectMemberRepo,
		TaskRepo:          taskRepo,
		UserRepo:          userRepo,
	}
}

func (u *ProjectUseCase) CreateProject(ctx context.Context, name string, createdBy int) (*domain.Project, error) {
	if name == "" {
		return nil, errors.New("название проекта обязательно")
	}

	project := &domain.Project{
		Name:      name,
		CreatedBy: createdBy,
	}
	if err := u.ProjectRepo.Create(ctx, project); err != nil {
		return nil, err
	}

	if err := u.ProjectMemberRepo.Add(ctx, project.Id, createdBy, createdBy); err != nil {
		return nil, err
	}

	return project, nil
}

func (u *ProjectUseCase) GetProjects(ctx context.Context, userId int, page, pageSize int32) ([]*domain.Project, int32, error) {
	return u.ProjectRepo.ListByUser(ctx, userId, page, pageSize)
}

func (u *ProjectUseCase) GetProject(ctx context.Context, id string, userId int) (*domain.Project, error) {
	project, err := u.ProjectRepo.GetById(ctx, id)
	if err != nil {
		return nil, err
	}

	isMember, err := u.ProjectMemberRepo.IsMember(ctx, id, userId)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	return project, nil
}

func (u *ProjectUseCase) AddUserToProject(ctx context.Context, projectId string, userIds []int64, createdBy int) error {
	isMember, err := u.ProjectMemberRepo.IsMember(ctx, projectId, createdBy)
	if err != nil {
		return err
	}
	if !isMember {
		return errors.New("доступ запрещён")
	}

	_, err = u.ProjectRepo.GetById(ctx, projectId)
	if err != nil {
		return err
	}

	for _, uid := range userIds {
		userId := int(uid)
		alreadyMember, err := u.ProjectMemberRepo.IsMember(ctx, projectId, userId)
		if err != nil {
			return err
		}

		if alreadyMember {
			continue
		}

		if err := u.ProjectMemberRepo.Add(ctx, projectId, userId, createdBy); err != nil {
			return err
		}
	}

	return nil
}

func (u *ProjectUseCase) GetProjectMembers(ctx context.Context, projectId string, userId int) ([]*domain.User, error) {
	isMember, err := u.ProjectMemberRepo.IsMember(ctx, projectId, userId)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	userIds, err := u.ProjectMemberRepo.GetByProjectId(ctx, projectId)
	if err != nil {
		return nil, err
	}

	users := make([]*domain.User, 0, len(userIds))
	for _, uid := range userIds {
		user, err := u.UserRepo.GetById(ctx, uid)
		if err != nil {
			continue
		}

		user.Password = ""
		users = append(users, user)
	}

	return users, nil
}

func (u *ProjectUseCase) CreateTask(ctx context.Context, projectId string, name string, description string, createdBy int, executor int) (*domain.Task, error) {
	if name == "" {
		return nil, errors.New("название задачи обязательно")
	}

	isMember, err := u.ProjectMemberRepo.IsMember(ctx, projectId, createdBy)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	_, err = u.ProjectRepo.GetById(ctx, projectId)
	if err != nil {
		return nil, err
	}

	isExecutorMember, err := u.ProjectMemberRepo.IsMember(ctx, projectId, executor)
	if err != nil {
		return nil, err
	}

	if !isExecutorMember {
		return nil, errors.New("ответственный должен быть участником проекта")
	}

	task := &domain.Task{
		ProjectId:   projectId,
		Name:        name,
		Description: description,
		CreatedBy:   createdBy,
		Assigner:    createdBy,
		Executor:    executor,
	}
	if err := u.TaskRepo.Create(ctx, task); err != nil {
		return nil, err
	}

	return task, nil
}

func (u *ProjectUseCase) GetTasks(ctx context.Context, projectId string, userId int) ([]*domain.Task, error) {
	isMember, err := u.ProjectMemberRepo.IsMember(ctx, projectId, userId)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	tasks, err := u.TaskRepo.ListByProjectId(ctx, projectId)
	if err != nil {
		return nil, err
	}

	return tasks, nil
}

func (u *ProjectUseCase) GetTask(ctx context.Context, taskId string, userId int) (*domain.Task, error) {
	task, err := u.TaskRepo.GetById(ctx, taskId)
	if err != nil {
		return nil, err
	}

	isMember, err := u.ProjectMemberRepo.IsMember(ctx, task.ProjectId, userId)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	return task, nil
}
