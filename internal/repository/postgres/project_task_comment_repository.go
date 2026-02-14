package postgres

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/magomedcoder/legion/internal/domain"
	"gorm.io/gorm"
)

type projectTaskCommentRepository struct {
	db *gorm.DB
}

func NewProjectTaskCommentRepository(db *gorm.DB) domain.ProjectTaskCommentRepository {
	return &projectTaskCommentRepository{db: db}
}

func (p *projectTaskCommentRepository) Create(ctx context.Context, comment *domain.TaskComment) error {
	taskId, err := uuid.Parse(comment.TaskId)
	if err != nil {
		return errors.New("неверный task_id")
	}

	m := &ProjectTaskCommentModel{
		TaskId: taskId,
		UserId: comment.UserId,
		Body:   comment.Body,
	}
	if err := p.db.WithContext(ctx).Create(m).Error; err != nil {
		return err
	}

	comment.Id = m.Id.String()
	if !m.CreatedAt.IsZero() {
		comment.CreatedAt = m.CreatedAt.Unix()
	}

	return nil
}

func (p *projectTaskCommentRepository) ListByTaskId(ctx context.Context, taskId string) ([]*domain.TaskComment, error) {
	parsed, err := uuid.Parse(taskId)
	if err != nil {
		return nil, errors.New("неверный task_id")
	}

	var list []ProjectTaskCommentModel
	if err := p.db.WithContext(ctx).
		Where("task_id = ?", parsed).
		Order("created_at ASC").
		Find(&list).Error; err != nil {
		return nil, err
	}

	comments := make([]*domain.TaskComment, 0, len(list))
	for _, m := range list {
		comments = append(comments, taskCommentModelToDomain(&m))
	}

	return comments, nil
}
