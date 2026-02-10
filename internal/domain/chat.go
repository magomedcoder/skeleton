package domain

import "time"

type Chat struct {
	Id         int
	ChatType   int
	UserId     int
	ReceiverId int
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

type Message struct {
	Id         int64
	ChatId     int
	ChatType   int
	UserId     int
	ReceiverId int
	Content    string
	CreatedAt  time.Time
}
