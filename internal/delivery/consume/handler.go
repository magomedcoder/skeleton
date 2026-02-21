package consume

import (
	"context"
	"log"
	"sync"

	"github.com/magomedcoder/legion/internal/config"
	"github.com/magomedcoder/legion/internal/domain"
	redisRepo "github.com/magomedcoder/legion/internal/repository/redis_repository"
	"github.com/magomedcoder/legion/internal/usecase"
)

type EventHandler func(ctx context.Context, data []byte)

var (
	eventHandlers map[string]EventHandler
	initHandlers  sync.Once
)

type Handler struct {
	Conf          *config.Config
	ClientCache   *redisRepo.ClientCacheRepository
	ChatUseCase   *usecase.ChatUseCase
	ProjectUseCase *usecase.ProjectUseCase
}

func (h *Handler) registerHandlers() {
	eventHandlers = map[string]EventHandler{
		domain.SubEventUserStatus:     h.handleUserStatus,
		domain.SubEventNewMessage:     h.onConsumeMessage,
		domain.SubEventMessageDeleted: h.onConsumeMessageDeleted,
		domain.SubEventMessageRead:    h.onConsumeMessageRead,
		domain.SubEventNewTask:        h.onConsumeNewTask,
		domain.SubEventTaskChanged:    h.onConsumeTaskChanged,
	}
}

func (h *Handler) Call(ctx context.Context, event string, data []byte) {
	initHandlers.Do(h.registerHandlers)

	if fn, ok := eventHandlers[event]; ok {
		fn(ctx, data)
	} else {
		log.Printf("Незарегистрированное событие обратного вызова: %s", event)
	}
}
