package consume

import "context"

type ChatSubscribe struct {
	Handler *Handler
}

func NewChatSubscribe(handler *Handler) *ChatSubscribe {
	return &ChatSubscribe{Handler: handler}
}

func (s *ChatSubscribe) Call(event string, data []byte) {
	s.Handler.Call(context.Background(), event, data)
}
