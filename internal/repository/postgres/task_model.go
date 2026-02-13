package postgres

import (
	"github.com/google/uuid"
	"time"

	"github.com/magomedcoder/legion/internal/domain"
)

type TaskModel struct {
	Id          uuid.UUID `gorm:"column:id;type:uuid;DEFAULT:gen_random_uuid()"`
	ProjectId   uuid.UUID `gorm:"column:project_id"`
	Name        string    `gorm:"column:name"`
	Description string    `gorm:"column:description"`
	CreatedBy   int       `gorm:"column:created_by"`
	CreatedAt   time.Time `gorm:"column:created_at"`
}

func (TaskModel) TableName() string {
	return "tasks"
}

func taskModelToDomain(m *TaskModel) *domain.Task {
	if m == nil {
		return nil
	}

	return &domain.Task{
		Id:          m.Id.String(),
		ProjectId:   m.ProjectId.String(),
		Name:        m.Name,
		Description: m.Description,
		CreatedBy:   m.CreatedBy,
		CreatedAt:   m.CreatedAt.Unix(),
	}
}

func taskDomainToModel(t *domain.Task) *TaskModel {
	if t == nil {
		return nil
	}

	projectId, _ := uuid.Parse(t.ProjectId)
	taskId := uuid.Nil
	if t.Id != "" {
		taskId, _ = uuid.Parse(t.Id)
	}

	return &TaskModel{
		Id:          taskId,
		ProjectId:   projectId,
		Name:        t.Name,
		Description: t.Description,
		CreatedBy:   t.CreatedBy,
		CreatedAt:   time.Unix(t.CreatedAt, 0),
	}
}
