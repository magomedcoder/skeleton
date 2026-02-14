package postgres

import (
	"github.com/google/uuid"
	"time"

	"github.com/magomedcoder/legion/internal/domain"
)

type ProjectTaskCommentModel struct {
	Id        uuid.UUID `gorm:"column:id;type:uuid;DEFAULT:gen_random_uuid()"`
	TaskId    uuid.UUID `gorm:"column:task_id"`
	UserId    int       `gorm:"column:user_id"`
	Body      string    `gorm:"column:body"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
}

func (ProjectTaskCommentModel) TableName() string {
	return "project_task_comments"
}

func taskCommentModelToDomain(p *ProjectTaskCommentModel) *domain.TaskComment {
	if p == nil {
		return nil
	}

	return &domain.TaskComment{
		Id:        p.Id.String(),
		TaskId:    p.TaskId.String(),
		UserId:    p.UserId,
		Body:      p.Body,
		CreatedAt: p.CreatedAt.Unix(),
	}
}

func projectTaskCommentDomainToModel(c *domain.TaskComment) *ProjectTaskCommentModel {
	if c == nil {
		return nil
	}

	taskId, _ := uuid.Parse(c.TaskId)
	commentId := uuid.Nil
	if c.Id != "" {
		commentId, _ = uuid.Parse(c.Id)
	}

	return &ProjectTaskCommentModel{
		Id:        commentId,
		TaskId:    taskId,
		UserId:    c.UserId,
		Body:      c.Body,
		CreatedAt: time.Unix(c.CreatedAt, 0),
	}
}
