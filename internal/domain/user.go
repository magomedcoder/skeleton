package domain

import (
	"time"
)

type UserRole int32

const (
	UserRoleUser  UserRole = 0
	UserRoleAdmin UserRole = 1
)

type User struct {
	Id            int
	Username      string
	Password      string
	Name          string
	Surname       string
	Role          UserRole
	CreatedAt     time.Time
	LastVisitedAt *time.Time
	DeletedAt     *time.Time
}
