package domain

import (
	"time"
)

type User struct {
	Id        int
	Email     string
	Password  string
	Name      string
	CreatedAt time.Time
}
