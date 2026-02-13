package handler

import (
	"context"

	"github.com/magomedcoder/legion/api/pb/commonpb"
	"github.com/magomedcoder/legion/api/pb/projectpb"
	"github.com/magomedcoder/legion/internal/delivery/mappers"
	"github.com/magomedcoder/legion/internal/delivery/middleware"
	"github.com/magomedcoder/legion/internal/usecase"
	error2 "github.com/magomedcoder/legion/pkg/error"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type Project struct {
	projectpb.UnimplementedProjectServiceServer
	ProjectUseCase *usecase.ProjectUseCase
}

func NewProjectHandler(
	projectUseCase *usecase.ProjectUseCase,
) *Project {
	return &Project{
		ProjectUseCase: projectUseCase,
	}
}

func (p *Project) getUserID(ctx context.Context) (int, error) {
	session := middleware.GetSession(ctx)
	if session == nil {
		return 0, status.Error(codes.Unauthenticated, "сессия не найдена")
	}

	return session.Uid, nil
}

func (p *Project) CreateProject(ctx context.Context, in *projectpb.CreateProjectRequest) (*projectpb.CreateProjectResponse, error) {
	uid, err := p.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	project, err := p.ProjectUseCase.CreateProject(ctx, in.Name, uid)
	if err != nil {
		return nil, error2.ToStatusError(codes.InvalidArgument, err)
	}

	return &projectpb.CreateProjectResponse{
		Id: project.Id,
	}, nil
}

func (p *Project) GetProjects(ctx context.Context, in *projectpb.GetProjectsRequest) (*projectpb.GetProjectsResponse, error) {
	uid, err := p.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	projects, _, err := p.ProjectUseCase.GetProjects(ctx, uid, 1, 1000)
	if err != nil {
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	items := make([]*projectpb.Project, 0, len(projects))
	for _, prj := range projects {
		items = append(items, &projectpb.Project{
			Id:   prj.Id,
			Name: prj.Name,
		})
	}

	return &projectpb.GetProjectsResponse{
		Items: items,
	}, nil
}

func (p *Project) GetProject(ctx context.Context, in *projectpb.GetProjectRequest) (*projectpb.GetProjectResponse, error) {
	uid, err := p.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	project, err := p.ProjectUseCase.GetProject(ctx, in.Id, uid)
	if err != nil {
		if err.Error() == "доступ запрещён" {
			return nil, status.Error(codes.PermissionDenied, err.Error())
		}

		if err.Error() == "проект не найден" {
			return nil, status.Error(codes.NotFound, err.Error())
		}

		return nil, error2.ToStatusError(codes.Internal, err)
	}

	return &projectpb.GetProjectResponse{
		Id:   project.Id,
		Name: project.Name,
	}, nil
}

func (p *Project) AddUserToProject(ctx context.Context, in *projectpb.AddUserToProjectRequest) (*projectpb.AddUserToProjectResponse, error) {
	uid, err := p.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	if len(in.UserIds) == 0 {
		return &projectpb.AddUserToProjectResponse{}, nil
	}

	err = p.ProjectUseCase.AddUserToProject(ctx, in.ProjectId, in.UserIds, uid)
	if err != nil {
		if err.Error() == "доступ запрещён" {
			return nil, status.Error(codes.PermissionDenied, err.Error())
		}

		if err.Error() == "проект не найден" {
			return nil, status.Error(codes.NotFound, err.Error())
		}

		return nil, error2.ToStatusError(codes.Internal, err)
	}

	return &projectpb.AddUserToProjectResponse{}, nil
}

func (p *Project) GetProjectMembers(ctx context.Context, in *projectpb.GetProjectMembersRequest) (*projectpb.GetProjectMembersResponse, error) {
	uid, err := p.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	users, err := p.ProjectUseCase.GetProjectMembers(ctx, in.ProjectId, uid)
	if err != nil {
		if err.Error() == "доступ запрещён" {
			return nil, status.Error(codes.PermissionDenied, err.Error())
		}
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	items := make([]*commonpb.User, 0, len(users))
	for _, u := range users {
		items = append(items, mappers.UserToProto(u))
	}

	return &projectpb.GetProjectMembersResponse{
		Items: items,
	}, nil
}

func (p *Project) CreateTask(ctx context.Context, in *projectpb.CreateTaskRequest) (*projectpb.CreateTaskResponse, error) {
	uid, err := p.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	if in.Executor <= 0 {
		return nil, status.Error(codes.InvalidArgument, "executor обязателен")
	}

	executor := int(in.Executor)
	task, err := p.ProjectUseCase.CreateTask(ctx, in.ProjectId, in.Name, in.Description, uid, executor)
	if err != nil {
		if err.Error() == "доступ запрещён" {
			return nil, status.Error(codes.PermissionDenied, err.Error())
		}
		return nil, error2.ToStatusError(codes.InvalidArgument, err)
	}

	return &projectpb.CreateTaskResponse{
		Id: task.Id,
	}, nil
}

func (p *Project) GetTasks(ctx context.Context, in *projectpb.GetTasksRequest) (*projectpb.GetTasksResponse, error) {
	uid, err := p.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	tasks, err := p.ProjectUseCase.GetTasks(ctx, in.ProjectId, uid)
	if err != nil {
		if err.Error() == "доступ запрещён" {
			return nil, status.Error(codes.PermissionDenied, err.Error())
		}
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	items := make([]*projectpb.Task, 0, len(tasks))
	for _, t := range tasks {
		items = append(items, &projectpb.Task{
			Id:          t.Id,
			Name:        t.Name,
			Description: t.Description,
			CreatedAt:   t.CreatedAt,
			Assigner:    int64(t.Assigner),
			Executor:    int64(t.Executor),
		})
	}

	return &projectpb.GetTasksResponse{
		Tasks: items,
	}, nil
}

func (p *Project) GetTask(ctx context.Context, in *projectpb.GetTaskRequest) (*projectpb.GetTaskResponse, error) {
	uid, err := p.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	task, err := p.ProjectUseCase.GetTask(ctx, in.TaskId, uid)
	if err != nil {
		if err.Error() == "доступ запрещён" {
			return nil, status.Error(codes.PermissionDenied, err.Error())
		}

		if err.Error() == "задача не найдена" {
			return nil, status.Error(codes.NotFound, err.Error())
		}

		return nil, error2.ToStatusError(codes.Internal, err)
	}

	return &projectpb.GetTaskResponse{
		Id:          task.Id,
		Name:        task.Name,
		Description: task.Description,
		CreatedAt:   task.CreatedAt,
		Assigner:    int64(task.Assigner),
		Executor:    int64(task.Executor),
	}, nil
}
