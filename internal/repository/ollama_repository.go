package repository

import (
	"context"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/service"
)

type OllamaRepository struct {
	client *service.OllamaService
}

func NewOllamaRepository(baseURL, model string) *OllamaRepository {
	return &OllamaRepository{
		client: service.NewOllamaService(baseURL, model),
	}
}

func (r *OllamaRepository) CheckConnection(ctx context.Context) (bool, error) {
	return r.client.CheckConnection(ctx)
}

func (r *OllamaRepository) SendMessage(ctx context.Context, sessionID string, messages []*domain.Message) (chan string, error) {
	return r.client.SendMessage(ctx, messages)
}
