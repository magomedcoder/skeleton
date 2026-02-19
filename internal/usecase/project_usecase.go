package usecase

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/magomedcoder/legion/internal/config"
	"github.com/magomedcoder/legion/internal/domain"
	redisRepo "github.com/magomedcoder/legion/internal/repository/redis_repository"
	"github.com/magomedcoder/legion/pkg/jsonutil"
	"github.com/redis/go-redis/v9"
)

type ProjectUseCase struct {
	ProjectRepo            domain.ProjectRepository
	ProjectMemberRepo      domain.ProjectMemberRepository
	ProjectTaskRepo        domain.ProjectTaskRepository
	ProjectTaskCommentRepo domain.ProjectTaskCommentRepository
	ProjectColumnRepo      domain.ProjectColumnRepository
	ProjectActivityRepo    domain.ProjectActivityRepository
	UserRepo               domain.UserRepository
	redis                  *redis.Client
	serverCache            *redisRepo.ServerCacheRepository
	clientCache            *redisRepo.ClientCacheRepository
	conf                   *config.Config
}

func NewProjectUseCase(
	projectRepo domain.ProjectRepository,
	projectMemberRepo domain.ProjectMemberRepository,
	projectTaskRepo domain.ProjectTaskRepository,
	projectTaskCommentRepo domain.ProjectTaskCommentRepository,
	projectColumnRepo domain.ProjectColumnRepository,
	projectActivityRepo domain.ProjectActivityRepository,
	userRepo domain.UserRepository,
	opts ...ProjectUseCaseOption,
) *ProjectUseCase {
	p := &ProjectUseCase{
		ProjectRepo:            projectRepo,
		ProjectMemberRepo:      projectMemberRepo,
		ProjectTaskRepo:        projectTaskRepo,
		ProjectTaskCommentRepo: projectTaskCommentRepo,
		ProjectColumnRepo:      projectColumnRepo,
		ProjectActivityRepo:    projectActivityRepo,
		UserRepo:               userRepo,
	}
	for _, opt := range opts {
		opt(p)
	}
	return p
}

type ProjectUseCaseOption func(*ProjectUseCase)

func WithProjectRedis(rds *redis.Client) ProjectUseCaseOption {
	return func(p *ProjectUseCase) {
		p.redis = rds
	}
}

func WithProjectServerCache(s *redisRepo.ServerCacheRepository) ProjectUseCaseOption {
	return func(p *ProjectUseCase) {
		p.serverCache = s
	}
}

func WithProjectClientCache(cl *redisRepo.ClientCacheRepository) ProjectUseCaseOption {
	return func(p *ProjectUseCase) {
		p.clientCache = cl
	}
}

func WithProjectConf(c *config.Config) ProjectUseCaseOption {
	return func(p *ProjectUseCase) {
		p.conf = c
	}
}

func (p *ProjectUseCase) CreateProject(ctx context.Context, name string, createdBy int) (*domain.Project, error) {
	if name == "" {
		return nil, errors.New("название проекта обязательно")
	}

	project := &domain.Project{
		Name:      name,
		CreatedBy: createdBy,
	}
	if err := p.ProjectRepo.Create(ctx, project); err != nil {
		return nil, err
	}

	if err := p.ProjectMemberRepo.Add(ctx, project.Id, createdBy, createdBy); err != nil {
		return nil, err
	}

	defaultColumns := []struct {
		title     string
		color     string
		statusKey string
		position  int32
	}{
		{"К выполнению", "#9E9E9E", "todo", 0},
		{"В работе", "#2196F3", "in_progress", 1},
		{"Готово", "#4CAF50", "done", 2},
	}

	for _, dc := range defaultColumns {
		col := &domain.ProjectColumn{
			ProjectId: project.Id,
			Title:     dc.title,
			Color:     dc.color,
			StatusKey: dc.statusKey,
			Position:  dc.position,
		}
		if err := p.ProjectColumnRepo.Create(ctx, col); err != nil {
			continue
		}
	}

	if err := p.recordActivity(ctx, project.Id, "", createdBy, "created_project", ""); err != nil {

	}

	return project, nil
}

func (p *ProjectUseCase) recordActivity(ctx context.Context, projectId, taskId string, userId int, action, payload string) error {
	a := &domain.ProjectActivity{
		ProjectId: projectId,
		TaskId:    taskId,
		UserId:    userId,
		Action:    action,
		Payload:   payload,
		CreatedAt: time.Now().Unix(),
	}

	return p.ProjectActivityRepo.Create(ctx, a)
}

func (p *ProjectUseCase) GetProjects(ctx context.Context, userId int, page, pageSize int32) ([]*domain.Project, int32, error) {
	return p.ProjectRepo.ListByUser(ctx, userId, page, pageSize)
}

func (p *ProjectUseCase) GetProject(ctx context.Context, id string, userId int) (*domain.Project, error) {
	project, err := p.ProjectRepo.GetById(ctx, id)
	if err != nil {
		return nil, err
	}

	isMember, err := p.ProjectMemberRepo.IsMember(ctx, id, userId)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	return project, nil
}

func (p *ProjectUseCase) AddUserToProject(ctx context.Context, projectId string, userIds []int64, createdBy int) error {
	isMember, err := p.ProjectMemberRepo.IsMember(ctx, projectId, createdBy)
	if err != nil {
		return err
	}
	if !isMember {
		return errors.New("доступ запрещён")
	}

	_, err = p.ProjectRepo.GetById(ctx, projectId)
	if err != nil {
		return err
	}

	for _, uid := range userIds {
		userId := int(uid)
		alreadyMember, err := p.ProjectMemberRepo.IsMember(ctx, projectId, userId)
		if err != nil {
			return err
		}

		if alreadyMember {
			continue
		}

		if err := p.ProjectMemberRepo.Add(ctx, projectId, userId, createdBy); err != nil {
			return err
		}
		_ = p.recordActivity(ctx, projectId, "", createdBy, "member_added", "")
	}

	return nil
}

func (p *ProjectUseCase) GetProjectMembers(ctx context.Context, projectId string, userId int) ([]*domain.User, error) {
	isMember, err := p.ProjectMemberRepo.IsMember(ctx, projectId, userId)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	userIds, err := p.ProjectMemberRepo.GetByProjectId(ctx, projectId)
	if err != nil {
		return nil, err
	}

	users := make([]*domain.User, 0, len(userIds))
	for _, uid := range userIds {
		user, err := p.UserRepo.GetById(ctx, uid)
		if err != nil {
			continue
		}

		user.Password = ""
		users = append(users, user)
	}

	return users, nil
}

func (p *ProjectUseCase) CreateTask(ctx context.Context, projectId string, name string, description string, createdBy int, executor int) (*domain.Task, error) {
	if name == "" {
		return nil, errors.New("название задачи обязательно")
	}

	isMember, err := p.ProjectMemberRepo.IsMember(ctx, projectId, createdBy)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	_, err = p.ProjectRepo.GetById(ctx, projectId)
	if err != nil {
		return nil, err
	}

	isExecutorMember, err := p.ProjectMemberRepo.IsMember(ctx, projectId, executor)
	if err != nil {
		return nil, err
	}

	if !isExecutorMember {
		return nil, errors.New("ответственный должен быть участником проекта")
	}

	columns, err := p.ProjectColumnRepo.ListByProjectId(ctx, projectId)
	if err != nil {
		return nil, err
	}
	var columnId string
	if len(columns) > 0 {
		columnId = columns[0].Id
	}

	task := &domain.Task{
		ProjectId:   projectId,
		Name:        name,
		Description: description,
		CreatedBy:   createdBy,
		Assigner:    createdBy,
		Executor:    executor,
		ColumnId:    columnId,
	}
	if err := p.ProjectTaskRepo.Create(ctx, task); err != nil {
		return nil, err
	}
	_ = p.recordActivity(ctx, projectId, task.Id, createdBy, "created_task", "")
	_ = p.PublishNewTask(ctx, projectId, task.Id)

	return task, nil
}

func (p *ProjectUseCase) GetTasks(ctx context.Context, projectId string, userId int) ([]*domain.Task, error) {
	isMember, err := p.ProjectMemberRepo.IsMember(ctx, projectId, userId)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	tasks, err := p.ProjectTaskRepo.ListByProjectId(ctx, projectId)
	if err != nil {
		return nil, err
	}

	return tasks, nil
}

func (p *ProjectUseCase) GetTask(ctx context.Context, taskId string, userId int) (*domain.Task, error) {
	task, err := p.ProjectTaskRepo.GetById(ctx, taskId)
	if err != nil {
		return nil, err
	}

	isMember, err := p.ProjectMemberRepo.IsMember(ctx, task.ProjectId, userId)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	return task, nil
}

func (p *ProjectUseCase) GetTaskById(ctx context.Context, taskId string) (*domain.Task, error) {
	return p.ProjectTaskRepo.GetById(ctx, taskId)
}

func (p *ProjectUseCase) GetProjectMemberIds(ctx context.Context, projectId string) ([]int, error) {
	return p.ProjectMemberRepo.GetByProjectId(ctx, projectId)
}

func (p *ProjectUseCase) publishTaskEvent(ctx context.Context, eventName, projectId, taskId string) error {
	if p.redis == nil || p.serverCache == nil || p.clientCache == nil || p.conf == nil {
		return nil
	}

	dataStr := jsonutil.Encode(map[string]any{
		"projectId": projectId,
		"taskId":    taskId,
	})

	content := jsonutil.Encode(map[string]any{
		"event": eventName,
		"data":  dataStr,
	})

	sids := p.serverCache.All(ctx, 1)
	if len(sids) == 0 {
		return nil
	}

	pipe := p.redis.Pipeline()
	for _, sid := range sids {
		memberIds, _ := p.ProjectMemberRepo.GetByProjectId(ctx, projectId)
		anyOnline := false
		for _, uid := range memberIds {
			if p.clientCache.IsCurrentServerOnline(ctx, sid, domain.ChatChannelName, fmt.Sprint(uid)) {
				anyOnline = true
				break
			}
		}
		
		if anyOnline {
			pipe.Publish(ctx, fmt.Sprintf(domain.LegionTopicByServer, sid), content)
		}
	}

	_, err := pipe.Exec(ctx)

	return err
}

func (p *ProjectUseCase) PublishNewTask(ctx context.Context, projectId, taskId string) error {
	return p.publishTaskEvent(ctx, domain.SubEventNewTask, projectId, taskId)
}

func (p *ProjectUseCase) PublishTaskChanged(ctx context.Context, projectId, taskId string) error {
	return p.publishTaskEvent(ctx, domain.SubEventTaskChanged, projectId, taskId)
}

func (p *ProjectUseCase) EditTaskColumnId(ctx context.Context, taskId string, columnId string, userId int) error {
	task, err := p.ProjectTaskRepo.GetById(ctx, taskId)
	if err != nil {
		return err
	}

	isMember, err := p.ProjectMemberRepo.IsMember(ctx, task.ProjectId, userId)
	if err != nil {
		return err
	}
	if !isMember {
		return errors.New("доступ запрещён")
	}

	if columnId != "" {
		col, err := p.ProjectColumnRepo.GetById(ctx, columnId)
		if err != nil {
			return errors.New("колонка не найдена")
		}
		if col.ProjectId != task.ProjectId {
			return errors.New("колонка не принадлежит проекту")
		}
	}

	if err := p.ProjectTaskRepo.EditColumnId(ctx, taskId, columnId); err != nil {
		return err
	}
	_ = p.recordActivity(ctx, task.ProjectId, taskId, userId, "moved_task", columnId)
	_ = p.PublishTaskChanged(ctx, task.ProjectId, taskId)

	return nil
}

func (p *ProjectUseCase) EditTask(ctx context.Context, taskId string, name string, description string, assigner int, executor int, userId int) (*domain.Task, error) {
	task, err := p.ProjectTaskRepo.GetById(ctx, taskId)
	if err != nil {
		return nil, err
	}

	isMember, err := p.ProjectMemberRepo.IsMember(ctx, task.ProjectId, userId)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	if name == "" {
		return nil, errors.New("название задачи обязательно")
	}

	isAssignerMember, err := p.ProjectMemberRepo.IsMember(ctx, task.ProjectId, assigner)
	if err != nil {
		return nil, err
	}
	if !isAssignerMember {
		return nil, errors.New("постановщик должен быть участником проекта")
	}

	isExecutorMember, err := p.ProjectMemberRepo.IsMember(ctx, task.ProjectId, executor)
	if err != nil {
		return nil, err
	}
	if !isExecutorMember {
		return nil, errors.New("исполнитель должен быть участником проекта")
	}

	task.Name = name
	task.Description = description
	task.Assigner = assigner
	task.Executor = executor

	if err := p.ProjectTaskRepo.Edit(ctx, task); err != nil {
		return nil, err
	}
	_ = p.recordActivity(ctx, task.ProjectId, task.Id, userId, "edited_task", "")
	_ = p.PublishTaskChanged(ctx, task.ProjectId, task.Id)

	return task, nil
}

func (p *ProjectUseCase) GetProjectColumns(ctx context.Context, projectId string, userId int) ([]*domain.ProjectColumn, error) {
	isMember, err := p.ProjectMemberRepo.IsMember(ctx, projectId, userId)
	if err != nil {
		return nil, err
	}

	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	return p.ProjectColumnRepo.ListByProjectId(ctx, projectId)
}

func (p *ProjectUseCase) CreateProjectColumn(ctx context.Context, projectId string, title string, color string, statusKey string, userId int) (*domain.ProjectColumn, error) {
	isMember, err := p.ProjectMemberRepo.IsMember(ctx, projectId, userId)
	if err != nil {
		return nil, err
	}

	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	if title == "" {
		return nil, errors.New("название колонки обязательно")
	}

	if statusKey == "" {
		return nil, errors.New("ключ статуса обязателен")
	}

	exists, err := p.ProjectColumnRepo.ExistsStatusKey(ctx, projectId, statusKey, "")
	if err != nil {
		return nil, err
	}

	if exists {
		return nil, errors.New("колонка с таким ключом статуса уже существует")
	}

	list, err := p.ProjectColumnRepo.ListByProjectId(ctx, projectId)
	if err != nil {
		return nil, err
	}

	position := int32(len(list))
	col := &domain.ProjectColumn{
		ProjectId: projectId,
		Title:     title,
		Color:     color,
		StatusKey: statusKey,
		Position:  position,
	}
	if err := p.ProjectColumnRepo.Create(ctx, col); err != nil {
		return nil, err
	}
	_ = p.recordActivity(ctx, projectId, "", userId, "column_created", col.Title)

	return col, nil
}

func (p *ProjectUseCase) EditProjectColumn(ctx context.Context, colId string, title string, color string, statusKey string, position int32, userId int) (*domain.ProjectColumn, error) {
	col, err := p.ProjectColumnRepo.GetById(ctx, colId)
	if err != nil {
		return nil, err
	}

	isMember, err := p.ProjectMemberRepo.IsMember(ctx, col.ProjectId, userId)
	if err != nil {
		return nil, err
	}

	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	if title != "" {
		col.Title = title
	}

	if color != "" {
		col.Color = color
	}

	if statusKey != "" {
		exists, err := p.ProjectColumnRepo.ExistsStatusKey(ctx, col.ProjectId, statusKey, colId)
		if err != nil {
			return nil, err
		}
		if exists {
			return nil, errors.New("колонка с таким ключом статуса уже существует")
		}
		col.StatusKey = statusKey
	}

	if position >= 0 {
		col.Position = position
	}

	if err := p.ProjectColumnRepo.Edit(ctx, col); err != nil {
		return nil, err
	}
	_ = p.recordActivity(ctx, col.ProjectId, "", userId, "column_edited", col.Title)

	return p.ProjectColumnRepo.GetById(ctx, col.Id)
}

func (p *ProjectUseCase) DeleteProjectColumn(ctx context.Context, colId string, userId int) error {
	col, err := p.ProjectColumnRepo.GetById(ctx, colId)
	if err != nil {
		return err
	}

	isMember, err := p.ProjectMemberRepo.IsMember(ctx, col.ProjectId, userId)
	if err != nil {
		return err
	}

	if !isMember {
		return errors.New("доступ запрещён")
	}
	_ = p.recordActivity(ctx, col.ProjectId, "", userId, "column_deleted", col.Title)

	return p.ProjectColumnRepo.Delete(ctx, colId)
}

func (p *ProjectUseCase) AddTaskComment(ctx context.Context, taskId string, body string, userId int) (*domain.TaskComment, error) {
	task, err := p.ProjectTaskRepo.GetById(ctx, taskId)
	if err != nil {
		return nil, err
	}

	isMember, err := p.ProjectMemberRepo.IsMember(ctx, task.ProjectId, userId)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	body = strings.TrimSpace(body)
	if body == "" {
		return nil, errors.New("текст комментария не может быть пустым")
	}

	comment := &domain.TaskComment{
		TaskId: taskId,
		UserId: userId,
		Body:   body,
	}
	if err := p.ProjectTaskCommentRepo.Create(ctx, comment); err != nil {
		return nil, err
	}
	_ = p.recordActivity(ctx, task.ProjectId, taskId, userId, "comment_added", "")

	return comment, nil
}

func (p *ProjectUseCase) GetTaskComments(ctx context.Context, taskId string, userId int) ([]*domain.TaskComment, error) {
	task, err := p.ProjectTaskRepo.GetById(ctx, taskId)
	if err != nil {
		return nil, err
	}

	isMember, err := p.ProjectMemberRepo.IsMember(ctx, task.ProjectId, userId)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	return p.ProjectTaskCommentRepo.ListByTaskId(ctx, taskId)
}

func (p *ProjectUseCase) GetProjectHistory(ctx context.Context, projectId string, userId int) ([]*domain.ProjectActivity, error) {
	isMember, err := p.ProjectMemberRepo.IsMember(ctx, projectId, userId)
	if err != nil {
		return nil, err
	}

	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	return p.ProjectActivityRepo.ListByProjectId(ctx, projectId, 200)
}

func (p *ProjectUseCase) GetTaskHistory(ctx context.Context, taskId string, userId int) ([]*domain.ProjectActivity, error) {
	task, err := p.ProjectTaskRepo.GetById(ctx, taskId)
	if err != nil {
		return nil, err
	}

	isMember, err := p.ProjectMemberRepo.IsMember(ctx, task.ProjectId, userId)
	if err != nil {
		return nil, err
	}

	if !isMember {
		return nil, errors.New("доступ запрещён")
	}

	return p.ProjectActivityRepo.ListByTaskId(ctx, taskId, 200)
}
