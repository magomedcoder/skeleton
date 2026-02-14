package domain

import (
	"context"
)

type UserRepository interface {
	Create(ctx context.Context, user *User) error

	GetById(ctx context.Context, id int) (*User, error)

	GetByUsername(ctx context.Context, username string) (*User, error)

	List(ctx context.Context, page, pageSize int32) ([]*User, int32, error)

	Search(ctx context.Context, query string, page, pageSize int32) ([]*User, int32, error)

	Update(ctx context.Context, user *User) error

	UpdateLastVisitedAt(ctx context.Context, userID int) error
}

type UserSessionRepository interface {
	Create(ctx context.Context, token *Token) error

	GetByToken(ctx context.Context, token string) (*Token, error)

	DeleteByToken(ctx context.Context, token string) error

	DeleteByUserId(ctx context.Context, userId int, tokenType TokenType) error

	CountByUserIdAndType(ctx context.Context, userId int, tokenType TokenType) (int, error)

	DeleteOldestByUserIdAndType(ctx context.Context, userId int, tokenType TokenType, limit int) error

	ListByUserIdAndType(ctx context.Context, userId int, tokenType TokenType) ([]*Token, error)

	DeleteByIdAndUserId(ctx context.Context, id, userId int) error

	DeleteRefreshTokensByUserIdExcept(ctx context.Context, userId int, keepRefreshToken string) error
}

type AIChatRepository interface {
	Create(ctx context.Context, session *AIChatSession) error

	GetById(ctx context.Context, id string) (*AIChatSession, error)

	GetByUserId(ctx context.Context, userID int, page, pageSize int32) ([]*AIChatSession, int32, error)

	Update(ctx context.Context, session *AIChatSession) error

	Delete(ctx context.Context, id string) error
}

type AIChatMessageRepository interface {
	Create(ctx context.Context, message *AIChatMessage) error

	GetBySessionId(ctx context.Context, sessionID string, page, pageSize int32) ([]*AIChatMessage, int32, error)
}

type FileRepository interface {
	Create(ctx context.Context, file *File) error

	GetById(ctx context.Context, id string) (*File, error)
}

type LLMProvider interface {
	CheckConnection(ctx context.Context) (bool, error)

	GetModels(ctx context.Context) ([]string, error)

	SendMessage(ctx context.Context, sessionID string, model string, messages []*AIChatMessage) (chan string, error)
}

type ChatRepository interface {
	GetById(ctx context.Context, id int) (*Chat, error)

	GetOrCreatePrivateChat(ctx context.Context, uid, userId int) (*Chat, error)

	ListByUser(ctx context.Context, uid int, page, pageSize int32) ([]*Chat, int32, error)
}

type ChatMessageRepository interface {
	Create(ctx context.Context, msg *Message) error

	ListByChatId(ctx context.Context, chatId int, page, pageSize int32) ([]*Message, int32, error)
}

type ProjectRepository interface {
	Create(ctx context.Context, project *Project) error

	GetById(ctx context.Context, id string) (*Project, error)

	ListByUser(ctx context.Context, userId int, page, pageSize int32) ([]*Project, int32, error)
}

type ProjectMemberRepository interface {
	Add(ctx context.Context, projectId string, userId int, createdBy int) error

	GetByProjectId(ctx context.Context, projectId string) ([]int, error)

	IsMember(ctx context.Context, projectId string, userId int) (bool, error)
}

type ProjectColumnRepository interface {
	Create(ctx context.Context, col *ProjectColumn) error

	GetById(ctx context.Context, id string) (*ProjectColumn, error)

	ListByProjectId(ctx context.Context, projectId string) ([]*ProjectColumn, error)

	Edit(ctx context.Context, col *ProjectColumn) error

	Delete(ctx context.Context, id string) error

	ExistsStatusKey(ctx context.Context, projectId string, statusKey string, excludeId string) (bool, error)
}

type ProjectTaskCommentRepository interface {
	Create(ctx context.Context, comment *TaskComment) error

	ListByTaskId(ctx context.Context, taskId string) ([]*TaskComment, error)
}

type ProjectTaskRepository interface {
	Create(ctx context.Context, task *Task) error

	GetById(ctx context.Context, id string) (*Task, error)

	ListByProjectId(ctx context.Context, projectId string) ([]*Task, error)

	EditColumnId(ctx context.Context, id string, columnId string) error

	Edit(ctx context.Context, task *Task) error
}

type ProjectActivityRepository interface {
	Create(ctx context.Context, a *ProjectActivity) error

	ListByProjectId(ctx context.Context, projectId string, limit int) ([]*ProjectActivity, error)

	ListByTaskId(ctx context.Context, taskId string, limit int) ([]*ProjectActivity, error)
}
