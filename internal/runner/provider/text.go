package provider

import (
	"context"
	"github.com/magomedcoder/skeleton/internal/domain"
)

type Text struct {
	backend TextBackend
}

func NewText(backend TextBackend) *Text {
	return &Text{
		backend: backend,
	}
}

func (t *Text) CheckConnection(ctx context.Context) (bool, error) {
	return t.backend.CheckConnection(ctx)
}

func (t *Text) GetModels(ctx context.Context) ([]string, error) {
	return t.backend.GetModels(ctx)
}

func (t *Text) SendMessage(ctx context.Context, sessionId string, model string, messages []*domain.AIChatMessage) (chan string, error) {
	return t.backend.SendMessage(ctx, model, messages)
}
