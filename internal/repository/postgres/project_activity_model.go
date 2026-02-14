package postgres

import (
	"github.com/google/uuid"
	"github.com/magomedcoder/legion/internal/domain"
	"time"
)

type ProjectActivityModel struct {
	Id        uuid.UUID  `gorm:"column:id;type:uuid;DEFAULT:gen_random_uuid()"`
	ProjectId uuid.UUID  `gorm:"column:project_id"`
	TaskId    *uuid.UUID `gorm:"column:task_id"`
	UserId    int        `gorm:"column:user_id"`
	Action    string     `gorm:"column:action"`
	Payload   string     `gorm:"column:payload"`
	CreatedAt time.Time  `gorm:"column:created_at"`
}

func (ProjectActivityModel) TableName() string {
	return "project_activity"
}

func projectActivityModelToDomain(m *ProjectActivityModel) *domain.ProjectActivity {
	if m == nil {
		return nil
	}

	taskId := ""
	if m.TaskId != nil {
		taskId = m.TaskId.String()
	}

	return &domain.ProjectActivity{
		Id:        m.Id.String(),
		ProjectId: m.ProjectId.String(),
		TaskId:    taskId,
		UserId:    m.UserId,
		Action:    m.Action,
		Payload:   m.Payload,
		CreatedAt: m.CreatedAt.Unix(),
	}
}

func projectActivityDomainToModel(a *domain.ProjectActivity) *ProjectActivityModel {
	if a == nil {
		return nil
	}

	projectId, _ := uuid.Parse(a.ProjectId)
	var taskId *uuid.UUID
	if a.TaskId != "" {
		parsed, _ := uuid.Parse(a.TaskId)
		taskId = &parsed
	}

	return &ProjectActivityModel{
		ProjectId: projectId,
		TaskId:    taskId,
		UserId:    a.UserId,
		Action:    a.Action,
		Payload:   a.Payload,
		CreatedAt: time.Unix(a.CreatedAt, 0),
	}
}
