package postgres

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/pkg"
	"gorm.io/gorm"
)

type taskRepository struct {
	db *gorm.DB
}

func NewTaskRepository(db *gorm.DB) domain.TaskRepository {
	return &taskRepository{db: db}
}

func (r *taskRepository) Create(ctx context.Context, task *domain.Task) error {
	projectId, err := uuid.Parse(task.ProjectId)
	if err != nil {
		return errors.New("неверный project_id")
	}

	m := &TaskModel{
		ProjectId:   projectId,
		Name:        task.Name,
		Description: task.Description,
		CreatedBy:   task.CreatedBy,
	}
	if err := r.db.WithContext(ctx).Create(m).Error; err != nil {
		return err
	}

	task.Id = m.Id.String()
	if !m.CreatedAt.IsZero() {
		task.CreatedAt = m.CreatedAt.Unix()
	}

	return nil
}

func (r *taskRepository) GetById(ctx context.Context, id string) (*domain.Task, error) {
	parsed, err := uuid.Parse(id)
	if err != nil {
		return nil, errors.New("задача не найдена")
	}

	var m TaskModel
	if err := r.db.WithContext(ctx).Where("id = ?", parsed).First(&m).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, pkg.HandleNotFound(err, "задача не найдена")
		}
		return nil, err
	}

	return taskModelToDomain(&m), nil
}

func (r *taskRepository) ListByProjectId(ctx context.Context, projectId string) ([]*domain.Task, error) {
	parsed, err := uuid.Parse(projectId)
	if err != nil {
		return nil, errors.New("неверный project_id")
	}

	var list []TaskModel
	if err := r.db.WithContext(ctx).
		Where("project_id = ?", parsed).
		Order("created_at DESC").
		Find(&list).Error; err != nil {
		return nil, err
	}

	tasks := make([]*domain.Task, 0, len(list))
	for _, m := range list {
		tasks = append(tasks, taskModelToDomain(&m))
	}

	return tasks, nil
}
