package postgres

import (
	"github.com/google/uuid"
	"time"
)

type ProjectMemberModel struct {
	Id        int       `gorm:"primaryKey"`
	ProjectId uuid.UUID `gorm:"column:project_id"`
	UserId    int       `gorm:"column:user_id"`
	CreatedBy int       `gorm:"column:created_by"`
	CreatedAt time.Time `gorm:"column:created_at"`
}

func (ProjectMemberModel) TableName() string {
	return "project_members"
}
