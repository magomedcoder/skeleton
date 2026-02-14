package postgres

import (
	"context"

	"github.com/google/uuid"
	"github.com/magomedcoder/legion/internal/domain"
	"gorm.io/gorm"
)

type projectActivityRepository struct {
	db *gorm.DB
}

func NewProjectActivityRepository(db *gorm.DB) domain.ProjectActivityRepository {
	return &projectActivityRepository{db: db}
}

func (p *projectActivityRepository) Create(ctx context.Context, a *domain.ProjectActivity) error {
	m := projectActivityDomainToModel(a)
	if a.Id != "" {
		parsed, err := uuid.Parse(a.Id)
		if err == nil {
			m.Id = parsed
		}
	}

	if err := p.db.WithContext(ctx).Create(m).Error; err != nil {
		return err
	}

	a.Id = m.Id.String()
	a.CreatedAt = m.CreatedAt.Unix()

	return nil
}

func (p *projectActivityRepository) ListByProjectId(ctx context.Context, projectId string, limit int) ([]*domain.ProjectActivity, error) {
	parsed, err := uuid.Parse(projectId)
	if err != nil {
		return nil, err
	}

	if limit <= 0 {
		limit = 100
	}

	var list []ProjectActivityModel
	if err := p.db.WithContext(ctx).
		Where("project_id = ?", parsed).
		Order("created_at DESC").
		Limit(limit).
		Find(&list).Error; err != nil {
		return nil, err
	}

	out := make([]*domain.ProjectActivity, 0, len(list))
	for i := range list {
		out = append(out, projectActivityModelToDomain(&list[i]))
	}

	return out, nil
}

func (p *projectActivityRepository) ListByTaskId(ctx context.Context, taskId string, limit int) ([]*domain.ProjectActivity, error) {
	parsed, err := uuid.Parse(taskId)
	if err != nil {
		return nil, err
	}

	if limit <= 0 {
		limit = 100
	}

	var list []ProjectActivityModel
	if err := p.db.WithContext(ctx).
		Where("task_id = ?", parsed).
		Order("created_at DESC").
		Limit(limit).
		Find(&list).Error; err != nil {
		return nil, err
	}

	out := make([]*domain.ProjectActivity, 0, len(list))
	for i := range list {
		out = append(out, projectActivityModelToDomain(&list[i]))
	}

	return out, nil
}
