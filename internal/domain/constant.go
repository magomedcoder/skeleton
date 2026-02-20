package domain

const (
	LegionTopicAll      = "legion:updates:all"
	LegionTopicByServer = "legion:updates:%s"
)

const (
	SubEventUserStatus     = "sub.user.status"
	SubEventNewMessage     = "sub.message.new"
	SubEventMessageDeleted = "sub.message.deleted"
	SubEventNewTask        = "sub.task.new"
	SubEventTaskChanged    = "sub.task.changed"
)

const ChatChannelName = "chat"
