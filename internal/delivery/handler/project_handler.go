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
			ColumnId:    t.ColumnId,
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
		ColumnId:    task.ColumnId,
	}, nil
}

func (p *Project) EditTaskColumnId(ctx context.Context, in *projectpb.EditTaskColumnIdRequest) (*projectpb.EditTaskColumnIdResponse, error) {
	uid, err := p.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	err = p.ProjectUseCase.EditTaskColumnId(ctx, in.TaskId, in.ColumnId, uid)
	if err != nil {
		if err.Error() == "доступ запрещён" {
			return nil, status.Error(codes.PermissionDenied, err.Error())
		}
		if err.Error() == "задача не найдена" || err.Error() == "колонка не найдена" {
			return nil, status.Error(codes.NotFound, err.Error())
		}
		return nil, error2.ToStatusError(codes.InvalidArgument, err)
	}

	return &projectpb.EditTaskColumnIdResponse{}, nil
}

func (p *Project) EditTask(ctx context.Context, in *projectpb.EditTaskRequest) (*projectpb.EditTaskResponse, error) {
	uid, err := p.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	if in.Name == "" {
		return nil, status.Error(codes.InvalidArgument, "название задачи обязательно")
	}

	if in.Assigner <= 0 || in.Executor <= 0 {
		return nil, status.Error(codes.InvalidArgument, "постановщик и исполнитель обязательны")
	}

	_, err = p.ProjectUseCase.EditTask(ctx, in.TaskId, in.Name, in.Description, int(in.Assigner), int(in.Executor), uid)
	if err != nil {
		if err.Error() == "доступ запрещён" {
			return nil, status.Error(codes.PermissionDenied, err.Error())
		}

		if err.Error() == "задача не найдена" {
			return nil, status.Error(codes.NotFound, err.Error())
		}

		if err.Error() == "постановщик должен быть участником проекта" || err.Error() == "исполнитель должен быть участником проекта" {
			return nil, status.Error(codes.InvalidArgument, err.Error())
		}

		return nil, error2.ToStatusError(codes.InvalidArgument, err)
	}

	return &projectpb.EditTaskResponse{}, nil
}

func (p *Project) GetProjectColumns(ctx context.Context, in *projectpb.GetProjectColumnsRequest) (*projectpb.GetProjectColumnsResponse, error) {
	uid, err := p.getUserID(ctx)
	if err != nil {
		return nil, err
	}
	cols, err := p.ProjectUseCase.GetProjectColumns(ctx, in.ProjectId, uid)
	if err != nil {
		if err.Error() == "доступ запрещён" {
			return nil, status.Error(codes.PermissionDenied, err.Error())
		}
		return nil, error2.ToStatusError(codes.Internal, err)
	}
	items := make([]*projectpb.ProjectColumn, 0, len(cols))
	for _, c := range cols {
		items = append(items, &projectpb.ProjectColumn{
			Id:        c.Id,
			ProjectId: c.ProjectId,
			Title:     c.Title,
			Color:     c.Color,
			StatusKey: c.StatusKey,
			Position:  c.Position,
		})
	}
	return &projectpb.GetProjectColumnsResponse{Columns: items}, nil
}

func (p *Project) CreateProjectColumn(ctx context.Context, in *projectpb.CreateProjectColumnRequest) (*projectpb.CreateProjectColumnResponse, error) {
	uid, err := p.getUserID(ctx)
	if err != nil {
		return nil, err
	}
	if in.Title == "" {
		return nil, status.Error(codes.InvalidArgument, "название обязательно")
	}
	statusKey := in.StatusKey
	if statusKey == "" {
		statusKey = slugFromTitle(in.Title)
	}
	color := in.Color
	if color == "" {
		color = "#9E9E9E"
	}
	col, err := p.ProjectUseCase.CreateProjectColumn(ctx, in.ProjectId, in.Title, color, statusKey, uid)
	if err != nil {
		if err.Error() == "доступ запрещён" {
			return nil, status.Error(codes.PermissionDenied, err.Error())
		}
		if err.Error() == "колонка с таким ключом статуса уже существует" {
			return nil, status.Error(codes.InvalidArgument, err.Error())
		}
		return nil, error2.ToStatusError(codes.InvalidArgument, err)
	}
	return &projectpb.CreateProjectColumnResponse{Id: col.Id}, nil
}

func (p *Project) EditProjectColumn(ctx context.Context, in *projectpb.EditProjectColumnRequest) (*projectpb.EditProjectColumnResponse, error) {
	uid, err := p.getUserID(ctx)
	if err != nil {
		return nil, err
	}
	if in.Id == "" {
		return nil, status.Error(codes.InvalidArgument, "id колонки обязателен")
	}
	position := int32(-1)
	if in.Position >= 0 {
		position = in.Position
	}
	_, err = p.ProjectUseCase.EditProjectColumn(ctx, in.Id, in.Title, in.Color, in.StatusKey, position, uid)
	if err != nil {
		if err.Error() == "доступ запрещён" {
			return nil, status.Error(codes.PermissionDenied, err.Error())
		}
		if err.Error() == "колонка не найдена" {
			return nil, status.Error(codes.NotFound, err.Error())
		}
		if err.Error() == "колонка с таким ключом статуса уже существует" {
			return nil, status.Error(codes.InvalidArgument, err.Error())
		}
		return nil, error2.ToStatusError(codes.Internal, err)
	}
	return &projectpb.EditProjectColumnResponse{}, nil
}

func (p *Project) DeleteProjectColumn(ctx context.Context, in *projectpb.DeleteProjectColumnRequest) (*projectpb.DeleteProjectColumnResponse, error) {
	uid, err := p.getUserID(ctx)
	if err != nil {
		return nil, err
	}
	if err := p.ProjectUseCase.DeleteProjectColumn(ctx, in.Id, uid); err != nil {
		if err.Error() == "доступ запрещён" {
			return nil, status.Error(codes.PermissionDenied, err.Error())
		}
		if err.Error() == "колонка не найдена" {
			return nil, status.Error(codes.NotFound, err.Error())
		}
		return nil, error2.ToStatusError(codes.Internal, err)
	}
	return &projectpb.DeleteProjectColumnResponse{}, nil
}

func (p *Project) AddTaskComment(ctx context.Context, in *projectpb.AddTaskCommentRequest) (*projectpb.AddTaskCommentResponse, error) {
	uid, err := p.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	if in.TaskId == "" {
		return nil, status.Error(codes.InvalidArgument, "task_id обязателен")
	}

	if in.Body == "" {
		return nil, status.Error(codes.InvalidArgument, "текст комментария обязателен")
	}

	comment, err := p.ProjectUseCase.AddTaskComment(ctx, in.TaskId, in.Body, uid)
	if err != nil {
		if err.Error() == "доступ запрещён" {
			return nil, status.Error(codes.PermissionDenied, err.Error())
		}

		if err.Error() == "задача не найдена" {
			return nil, status.Error(codes.NotFound, err.Error())
		}

		if err.Error() == "текст комментария не может быть пустым" {
			return nil, status.Error(codes.InvalidArgument, err.Error())
		}

		return nil, error2.ToStatusError(codes.InvalidArgument, err)
	}

	return &projectpb.AddTaskCommentResponse{Id: comment.Id}, nil
}

func (p *Project) GetTaskComments(ctx context.Context, in *projectpb.GetTaskCommentsRequest) (*projectpb.GetTaskCommentsResponse, error) {
	uid, err := p.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	if in.TaskId == "" {
		return nil, status.Error(codes.InvalidArgument, "task_id обязателен")
	}

	comments, err := p.ProjectUseCase.GetTaskComments(ctx, in.TaskId, uid)
	if err != nil {
		if err.Error() == "доступ запрещён" {
			return nil, status.Error(codes.PermissionDenied, err.Error())
		}

		if err.Error() == "задача не найдена" {
			return nil, status.Error(codes.NotFound, err.Error())
		}

		return nil, error2.ToStatusError(codes.Internal, err)
	}

	items := make([]*projectpb.TaskComment, 0, len(comments))
	for _, c := range comments {
		items = append(items, &projectpb.TaskComment{
			Id:        c.Id,
			TaskId:    c.TaskId,
			UserId:    int64(c.UserId),
			Body:      c.Body,
			CreatedAt: c.CreatedAt,
		})
	}

	return &projectpb.GetTaskCommentsResponse{Comments: items}, nil
}

func slugFromTitle(title string) string {
	var b []byte
	for _, r := range title {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') {
			b = append(b, byte(r))
		} else if r >= 'A' && r <= 'Z' {
			b = append(b, byte(r+32))
		} else if r == ' ' || r == '-' || r == '_' {
			if len(b) > 0 && b[len(b)-1] != '_' {
				b = append(b, '_')
			}
		}
	}
	if len(b) == 0 {
		return "column"
	}
	if b[len(b)-1] == '_' {
		b = b[:len(b)-1]
	}
	return string(b)
}
