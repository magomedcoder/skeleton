package provider

import (
	"context"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/runner/service"
)

type Text struct {
	client *service.OllamaService
}

func NewText(client *service.OllamaService) *Text {
	return &Text{
		client: client,
	}
}

func (t *Text) CheckConnection(ctx context.Context) (bool, error) {
	return t.client.CheckConnection(ctx)
}

func (t *Text) GetModels(ctx context.Context) ([]string, error) {
	return t.client.GetModels(ctx)
}

func (t *Text) SendMessage(ctx context.Context, sessionId string, model string, messages []*domain.Message) (chan string, error) {
	return t.client.SendMessage(ctx, model, messages)
}
