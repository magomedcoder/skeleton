package event

import (
	"context"
	"log"
	"sync"

	"github.com/magomedcoder/legion/internal/pkg/socket"
	"github.com/redis/go-redis/v9"
)

type EventHandlerFn func(ctx context.Context, client socket.IClient, data []byte)

type Handler struct {
	Redis    *redis.Client
	Handlers map[string]EventHandlerFn
	initOnce sync.Once
}

func NewHandler(redis *redis.Client) *Handler {
	return &Handler{
		Redis: redis,
	}
}

func (h *Handler) ensureHandlers() {
	h.initOnce.Do(func() {
		h.Handlers = make(map[string]EventHandlerFn)
	})
}

func (h *Handler) Call(ctx context.Context, client socket.IClient, event string, data []byte) {
	h.ensureHandlers()

	if fn, ok := h.Handlers[event]; ok {
		fn(ctx, client, data)
	} else {
		log.Printf("Чат: для события %s не зарегистрирован обработчик", event)
	}
}
