package domain

import (
	"time"
)

type User struct {
	Id        int
	Username  string
	Password  string
	Name      string
	CreatedAt time.Time
	DeletedAt *time.Time
}
