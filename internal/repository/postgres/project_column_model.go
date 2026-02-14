package postgres

import (
	"github.com/google/uuid"
	"github.com/magomedcoder/legion/internal/domain"
)

type ProjectColumnModel struct {
	Id        uuid.UUID `gorm:"column:id;type:uuid;DEFAULT:gen_random_uuid()"`
	ProjectId uuid.UUID `gorm:"column:project_id"`
	Title     string    `gorm:"column:title"`
	Color     string    `gorm:"column:color"`
	StatusKey string    `gorm:"column:status_key"`
	Position  int       `gorm:"column:position"`
}

func (ProjectColumnModel) TableName() string {
	return "project_columns"
}

func projectColumnModelToDomain(m *ProjectColumnModel) *domain.ProjectColumn {
	if m == nil {
		return nil
	}

	return &domain.ProjectColumn{
		Id:        m.Id.String(),
		ProjectId: m.ProjectId.String(),
		Title:     m.Title,
		Color:     m.Color,
		StatusKey: m.StatusKey,
		Position:  int32(m.Position),
	}
}

func projectColumnDomainToModel(c *domain.ProjectColumn) *ProjectColumnModel {
	if c == nil {
		return nil
	}

	projectId, _ := uuid.Parse(c.ProjectId)
	colId := uuid.Nil
	if c.Id != "" {
		colId, _ = uuid.Parse(c.Id)
	}

	return &ProjectColumnModel{
		Id:        colId,
		ProjectId: projectId,
		Title:     c.Title,
		Color:     c.Color,
		StatusKey: c.StatusKey,
		Position:  int(c.Position),
	}
}
