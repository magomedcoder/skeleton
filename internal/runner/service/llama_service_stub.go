//go:build !llama
// +build !llama

package service

import (
	"context"
	"fmt"
	"github.com/magomedcoder/legion/internal/domain"
)

type LlamaService struct{}

type LlamaOption func(*LlamaService)

func NewLlamaService(modelPath string, opts ...LlamaOption) *LlamaService {
	return &LlamaService{}
}

func (s *LlamaService) CheckConnection(ctx context.Context) (bool, error) {
	return false, fmt.Errorf("llama отключена")
}

func (s *LlamaService) GetModels(ctx context.Context) ([]string, error) {
	return nil, fmt.Errorf("llama отключена")
}

func (s *LlamaService) SendMessage(ctx context.Context, model string, messages []*domain.AIChatMessage) (chan string, error) {
	ch := make(chan string)
	close(ch)
	return ch, fmt.Errorf("llama отключена")
}
