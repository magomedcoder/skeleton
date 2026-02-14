package postgres

import (
	"github.com/google/uuid"
	"time"

	"github.com/magomedcoder/legion/internal/domain"
)

type TaskCommentModel struct {
	Id        uuid.UUID `gorm:"column:id;type:uuid;DEFAULT:gen_random_uuid()"`
	TaskId    uuid.UUID `gorm:"column:task_id"`
	UserId    int       `gorm:"column:user_id"`
	Body      string    `gorm:"column:body"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
}

func (TaskCommentModel) TableName() string {
	return "task_comments"
}

func taskCommentModelToDomain(m *TaskCommentModel) *domain.TaskComment {
	if m == nil {
		return nil
	}

	return &domain.TaskComment{
		Id:        m.Id.String(),
		TaskId:    m.TaskId.String(),
		UserId:    m.UserId,
		Body:      m.Body,
		CreatedAt: m.CreatedAt.Unix(),
	}
}

func taskCommentDomainToModel(c *domain.TaskComment) *TaskCommentModel {
	if c == nil {
		return nil
	}

	taskId, _ := uuid.Parse(c.TaskId)
	commentId := uuid.Nil
	if c.Id != "" {
		commentId, _ = uuid.Parse(c.Id)
	}

	return &TaskCommentModel{
		Id:        commentId,
		TaskId:    taskId,
		UserId:    c.UserId,
		Body:      c.Body,
		CreatedAt: time.Unix(c.CreatedAt, 0),
	}
}
