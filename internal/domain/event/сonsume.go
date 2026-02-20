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
	PeerType   int   `json:"peerType"`
	PeerId     int64 `json:"peerId"`
	FromPeerId int64 `json:"fromPeerId"`
	MessageId  int64 `json:"messageId"`
}

type ConsumeMessageDeleted struct {
	PeerId     int64   `json:"peerId"`
	FromPeerId int64   `json:"fromPeerId"`
	MessageIds []int64 `json:"messageIds"`
}

type ConsumeTask struct {
	ProjectId string `json:"projectId"`
	TaskId    string `json:"taskId"`
}
