package postgres

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/pkg"
	"gorm.io/gorm"
)

type projectColumnRepository struct {
	db *gorm.DB
}

func NewProjectColumnRepository(db *gorm.DB) domain.ProjectColumnRepository {
	return &projectColumnRepository{db: db}
}

func (r *projectColumnRepository) Create(ctx context.Context, col *domain.ProjectColumn) error {
	projectId, err := uuid.Parse(col.ProjectId)
	if err != nil {
		return errors.New("неверный project_id")
	}

	m := &ProjectColumnModel{
		ProjectId: projectId,
		Title:     col.Title,
		Color:     col.Color,
		StatusKey: col.StatusKey,
		Position:  int(col.Position),
	}
	if col.Id != "" {
		parsed, _ := uuid.Parse(col.Id)
		m.Id = parsed
	}

	if err := r.db.WithContext(ctx).Create(m).Error; err != nil {
		return err
	}

	col.Id = m.Id.String()

	return nil
}

func (r *projectColumnRepository) GetById(ctx context.Context, id string) (*domain.ProjectColumn, error) {
	parsed, err := uuid.Parse(id)
	if err != nil {
		return nil, errors.New("колонка не найдена")
	}

	var m ProjectColumnModel
	if err := r.db.WithContext(ctx).Where("id = ?", parsed).First(&m).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, pkg.HandleNotFound(err, "колонка не найдена")
		}
		return nil, err
	}

	return projectColumnModelToDomain(&m), nil
}

func (r *projectColumnRepository) ListByProjectId(ctx context.Context, projectId string) ([]*domain.ProjectColumn, error) {
	parsed, err := uuid.Parse(projectId)
	if err != nil {
		return nil, errors.New("неверный project_id")
	}

	var list []ProjectColumnModel
	if err := r.db.WithContext(ctx).
		Where("project_id = ?", parsed).
		Order("position ASC, id ASC").
		Find(&list).Error; err != nil {
		return nil, err
	}

	out := make([]*domain.ProjectColumn, 0, len(list))
	for _, m := range list {
		out = append(out, projectColumnModelToDomain(&m))
	}

	return out, nil
}

func (r *projectColumnRepository) Edit(ctx context.Context, col *domain.ProjectColumn) error {
	parsed, err := uuid.Parse(col.Id)
	if err != nil {
		return errors.New("неверный id колонки")
	}

	return r.db.WithContext(ctx).Model(&ProjectColumnModel{}).
		Where("id = ?", parsed).
		Updates(map[string]interface{}{
			"title":      col.Title,
			"color":      col.Color,
			"status_key": col.StatusKey,
			"position":   col.Position,
		}).Error
}

func (r *projectColumnRepository) Delete(ctx context.Context, id string) error {
	parsed, err := uuid.Parse(id)
	if err != nil {
		return errors.New("неверный id колонки")
	}

	return r.db.WithContext(ctx).Where("id = ?", parsed).Delete(&ProjectColumnModel{}).Error
}

func (r *projectColumnRepository) ExistsStatusKey(ctx context.Context, projectId string, statusKey string, excludeId string) (bool, error) {
	parsed, err := uuid.Parse(projectId)
	if err != nil {
		return false, errors.New("неверный project_id")
	}

	q := r.db.WithContext(ctx).Model(&ProjectColumnModel{}).
		Where("project_id = ? AND status_key = ?", parsed, statusKey)
	if excludeId != "" {
		ex, _ := uuid.Parse(excludeId)
		q = q.Where("id != ?", ex)
	}

	var count int64
	if err := q.Count(&count).Error; err != nil {
		return false, err
	}

	return count > 0, nil
}
