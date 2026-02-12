package postgres

import (
	"github.com/google/uuid"
	"time"
)

type ProjectModel struct {
	Id        uuid.UUID `gorm:"column:id;type:uuid;DEFAULT:gen_random_uuid()"`
	Name      string    `gorm:"column:name"`
	CreatedBy int       `gorm:"column:created_by"`
	CreatedAt time.Time `gorm:"column:created_at"`
}

func (ProjectModel) TableName() string {
	return "projects"
}
