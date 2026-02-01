package provider

import (
	"context"
	"github.com/magomedcoder/legion/internal/domain"
)

type TextProvider interface {
	CheckConnection(ctx context.Context) (bool, error)

	GetModels(ctx context.Context) ([]string, error)

	SendMessage(ctx context.Context, sessionId string, model string, messages []*domain.Message) (chan string, error)
}
