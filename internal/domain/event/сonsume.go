package event

type SubscribeContent struct {
	Event string
	Data  string
}

type ConsumeUserStatus struct {
	UserId int  `json:"userId"`
	Status bool `json:"status"`
}

type ConsumeMessage struct {
	ChatType  int   `json:"chatType"`
	SenderId  int64 `json:"senderId"`
	ToId      int64 `json:"toId"`
	MessageId int64 `json:"messageId"`
}
