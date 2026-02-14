package postgres

import (
	"github.com/google/uuid"
	"time"

	"github.com/magomedcoder/legion/internal/domain"
)

type ProjectTaskModel struct {
	Id          uuid.UUID  `gorm:"column:id;type:uuid;DEFAULT:gen_random_uuid()"`
	ProjectId   uuid.UUID  `gorm:"column:project_id"`
	Name        string     `gorm:"column:name"`
	Description string     `gorm:"column:description"`
	CreatedBy   int        `gorm:"column:created_by"`
	CreatedAt   time.Time  `gorm:"column:created_at"`
	Assigner    int        `gorm:"column:assigner"`
	Executor    int        `gorm:"column:executor"`
	ColumnId    *uuid.UUID `gorm:"column:column_id"`
}

func (ProjectTaskModel) TableName() string {
	return "project_tasks"
}

func taskModelToDomain(p *ProjectTaskModel) *domain.Task {
	if p == nil {
		return nil
	}

	columnId := ""
	if p.ColumnId != nil {
		columnId = p.ColumnId.String()
	}

	return &domain.Task{
		Id:          p.Id.String(),
		ProjectId:   p.ProjectId.String(),
		Name:        p.Name,
		Description: p.Description,
		CreatedBy:   p.CreatedBy,
		CreatedAt:   p.CreatedAt.Unix(),
		Assigner:    p.Assigner,
		Executor:    p.Executor,
		ColumnId:    columnId,
	}
}

func projectTaskDomainToModel(t *domain.Task) *ProjectTaskModel {
	if t == nil {
		return nil
	}

	projectId, _ := uuid.Parse(t.ProjectId)
	taskId := uuid.Nil
	if t.Id != "" {
		taskId, _ = uuid.Parse(t.Id)
	}

	var columnId *uuid.UUID
	if t.ColumnId != "" {
		parsed, _ := uuid.Parse(t.ColumnId)
		columnId = &parsed
	}

	return &ProjectTaskModel{
		Id:          taskId,
		ProjectId:   projectId,
		Name:        t.Name,
		Description: t.Description,
		CreatedBy:   t.CreatedBy,
		CreatedAt:   time.Unix(t.CreatedAt, 0),
		Assigner:    t.Assigner,
		Executor:    t.Executor,
		ColumnId:    columnId,
	}
}
