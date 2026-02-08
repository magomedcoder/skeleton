package provider

import (
	"context"
	"fmt"
	"github.com/magomedcoder/skeleton/internal/domain"
	"github.com/magomedcoder/skeleton/internal/runner/config"
	"github.com/magomedcoder/skeleton/internal/runner/service"
)

type TextBackend interface {
	CheckConnection(ctx context.Context) (bool, error)

	GetModels(ctx context.Context) ([]string, error)

	SendMessage(ctx context.Context, model string, messages []*domain.AIChatMessage) (chan string, error)
}

type TextProvider interface {
	CheckConnection(ctx context.Context) (bool, error)

	GetModels(ctx context.Context) ([]string, error)

	SendMessage(ctx context.Context, sessionId string, model string, messages []*domain.AIChatMessage) (chan string, error)
}

func NewTextProvider(cfg *config.Config) (TextProvider, error) {
	switch cfg.Engine {
	case config.EngineLlama:
		if cfg.Llama.ModelPath == "" {
			return nil, fmt.Errorf("движок %q: задайте llama.model_path", config.EngineLlama)
		}
		svc := service.NewLlamaService(cfg.Llama.ModelPath)
		return NewText(svc), nil
	case config.EngineOllama:
		svc := service.NewOllamaService(cfg.Ollama)
		return NewText(svc), nil
	default:
		return nil, fmt.Errorf("движок не задан или неизвестен %q (ожидается %q или %q)", cfg.Engine, config.EngineOllama, config.EngineLlama)
	}
}
