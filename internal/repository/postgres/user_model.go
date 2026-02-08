package postgres

import (
	"time"

	"github.com/magomedcoder/legion/internal/domain"
	"gorm.io/gorm"
)

type userModel struct {
	Id            int            `gorm:"column:id;primaryKey;autoIncrement"`
	Username      string         `gorm:"column:username;size:255;uniqueIndex;not null"`
	Password      string         `gorm:"column:password;size:255;not null"`
	Name          string         `gorm:"column:name;size:255;not null"`
	Surname       string         `gorm:"column:surname;size:255;not null"`
	Role          int32          `gorm:"column:role;not null;default:0"`
	CreatedAt     time.Time      `gorm:"column:created_at;not null"`
	UpdatedAt     time.Time      `gorm:"column:updated_at;not null"`
	LastVisitedAt *time.Time     `gorm:"column:last_visited_at"`
	DeletedAt     gorm.DeletedAt `gorm:"column:deleted_at;index"`
}

func (userModel) TableName() string {
	return "users"
}

func userModelToDomain(m *userModel) *domain.User {
	if m == nil {
		return nil
	}

	var deletedAt *time.Time
	if m.DeletedAt.Valid {
		t := m.DeletedAt.Time
		deletedAt = &t
	}

	return &domain.User{
		Id:            m.Id,
		Username:      m.Username,
		Password:      m.Password,
		Name:          m.Name,
		Surname:       m.Surname,
		Role:          domain.UserRole(m.Role),
		CreatedAt:     m.CreatedAt,
		LastVisitedAt: m.LastVisitedAt,
		DeletedAt:     deletedAt,
	}
}

func userDomainToModel(u *domain.User) *userModel {
	if u == nil {
		return nil
	}

	var deletedAt gorm.DeletedAt
	if u.DeletedAt != nil {
		deletedAt = gorm.DeletedAt{Time: *u.DeletedAt, Valid: true}
	}

	return &userModel{
		Id:            u.Id,
		Username:      u.Username,
		Password:      u.Password,
		Name:          u.Name,
		Surname:       u.Surname,
		Role:          int32(u.Role),
		CreatedAt:     u.CreatedAt,
		LastVisitedAt: u.LastVisitedAt,
		DeletedAt:     deletedAt,
	}
}
