package postgres

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/magomedcoder/legion/internal/domain"
	"gorm.io/gorm"
)

type taskCommentRepository struct {
	db *gorm.DB
}

func NewTaskCommentRepository(db *gorm.DB) domain.TaskCommentRepository {
	return &taskCommentRepository{db: db}
}

func (r *taskCommentRepository) Create(ctx context.Context, comment *domain.TaskComment) error {
	taskId, err := uuid.Parse(comment.TaskId)
	if err != nil {
		return errors.New("неверный task_id")
	}

	m := &TaskCommentModel{
		TaskId: taskId,
		UserId: comment.UserId,
		Body:   comment.Body,
	}
	if err := r.db.WithContext(ctx).Create(m).Error; err != nil {
		return err
	}

	comment.Id = m.Id.String()
	if !m.CreatedAt.IsZero() {
		comment.CreatedAt = m.CreatedAt.Unix()
	}

	return nil
}

func (r *taskCommentRepository) ListByTaskId(ctx context.Context, taskId string) ([]*domain.TaskComment, error) {
	parsed, err := uuid.Parse(taskId)
	if err != nil {
		return nil, errors.New("неверный task_id")
	}

	var list []TaskCommentModel
	if err := r.db.WithContext(ctx).
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
