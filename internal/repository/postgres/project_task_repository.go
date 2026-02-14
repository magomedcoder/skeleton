package postgres

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/pkg"
	"gorm.io/gorm"
)

type projectTaskRepository struct {
	db *gorm.DB
}

func NewProjectTaskRepository(db *gorm.DB) domain.ProjectTaskRepository {
	return &projectTaskRepository{db: db}
}

func (p *projectTaskRepository) Create(ctx context.Context, task *domain.Task) error {
	projectId, err := uuid.Parse(task.ProjectId)
	if err != nil {
		return errors.New("неверный project_id")
	}

	var columnId *uuid.UUID
	if task.ColumnId != "" {
		parsed, err := uuid.Parse(task.ColumnId)
		if err != nil {
			return errors.New("неверный column_id")
		}
		columnId = &parsed
	}

	m := &ProjectTaskModel{
		ProjectId:   projectId,
		Name:        task.Name,
		Description: task.Description,
		CreatedBy:   task.CreatedBy,
		Assigner:    task.Assigner,
		Executor:    task.Executor,
		ColumnId:    columnId,
	}
	if err := p.db.WithContext(ctx).Create(m).Error; err != nil {
		return err
	}

	task.Id = m.Id.String()
	if !m.CreatedAt.IsZero() {
		task.CreatedAt = m.CreatedAt.Unix()
	}

	return nil
}

func (p *projectTaskRepository) GetById(ctx context.Context, id string) (*domain.Task, error) {
	parsed, err := uuid.Parse(id)
	if err != nil {
		return nil, errors.New("задача не найдена")
	}

	var m ProjectTaskModel
	if err := p.db.WithContext(ctx).Where("id = ?", parsed).First(&m).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, pkg.HandleNotFound(err, "задача не найдена")
		}
		return nil, err
	}

	return taskModelToDomain(&m), nil
}

func (p *projectTaskRepository) ListByProjectId(ctx context.Context, projectId string) ([]*domain.Task, error) {
	parsed, err := uuid.Parse(projectId)
	if err != nil {
		return nil, errors.New("неверный project_id")
	}

	var list []ProjectTaskModel
	if err := p.db.WithContext(ctx).
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

func (p *projectTaskRepository) EditColumnId(ctx context.Context, id string, columnId string) error {
	parsed, err := uuid.Parse(id)
	if err != nil {
		return errors.New("неверный id задачи")
	}

	var colId *uuid.UUID
	if columnId != "" {
		parsedCol, err := uuid.Parse(columnId)
		if err != nil {
			return errors.New("неверный column_id")
		}
		colId = &parsedCol
	}

	if err := p.db.WithContext(ctx).
		Model(&ProjectTaskModel{}).
		Where("id = ?", parsed).
		Update("column_id", colId).Error; err != nil {
		return err
	}

	return nil
}

func (p *projectTaskRepository) Edit(ctx context.Context, task *domain.Task) error {
	parsed, err := uuid.Parse(task.Id)
	if err != nil {
		return errors.New("неверный id задачи")
	}

	var columnId *uuid.UUID
	if task.ColumnId != "" {
		parsedCol, err := uuid.Parse(task.ColumnId)
		if err != nil {
			return errors.New("неверный column_id")
		}
		columnId = &parsedCol
	}

	updates := map[string]interface{}{
		"name":        task.Name,
		"description": task.Description,
		"assigner":    task.Assigner,
		"executor":    task.Executor,
		"column_id":   columnId,
	}

	if err := p.db.WithContext(ctx).
		Model(&ProjectTaskModel{}).
		Where("id = ?", parsed).
		Updates(updates).Error; err != nil {
		return err
	}

	return nil
}
