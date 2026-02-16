package event

type SubscribeContent struct {
	Event string
	Data  string
}

type ConsumeUserStatus struct {
	UserId int  `json:"userId"`
	Status bool `json:"status"`
}
