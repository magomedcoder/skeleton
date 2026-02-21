package domain

import "time"

type Chat struct {
	Id          int
	PeerType    int
	PeerId      int
	UserId      int
	CreatedAt   time.Time
	UpdatedAt   time.Time
	UnreadCount int
}

type Message struct {
	Id           int64
	PeerType     int
	PeerId       int
	FromPeerType int
	FromPeerId   int
	Content      string
	CreatedAt    time.Time
	IsRead       bool
}
