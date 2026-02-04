package service

import (
	"context"
	"fmt"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/pkg/llama.cpp"
	"path/filepath"
	"strings"
	"sync"
)

const defaultChunkSize = 128

type LlamaService struct {
	modelPath   string
	chunkSize   int
	predictOpts []llama.PredictOption
	mu          sync.Mutex
	model       *llama.LLama
}

type LlamaOption func(*LlamaService)

func WithChunkSize(n int) LlamaOption {
	return func(s *LlamaService) {
		if n > 0 {
			s.chunkSize = n
		}
	}
}

func WithPredictOptions(opts ...llama.PredictOption) LlamaOption {
	return func(s *LlamaService) {
		s.predictOpts = opts
	}
}

func NewLlamaService(modelPath string, opts ...LlamaOption) *LlamaService {
	s := &LlamaService{
		modelPath: modelPath,
		chunkSize: defaultChunkSize,
	}

	for _, opt := range opts {
		opt(s)
	}

	if s.chunkSize <= 0 {
		s.chunkSize = defaultChunkSize
	}

	return s
}

func (s *LlamaService) ensureModel() error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.model != nil {
		return nil
	}

	if s.modelPath == "" {
		return fmt.Errorf("llama: путь к модели не задан")
	}

	m, err := llama.New(s.modelPath)
	if err != nil {
		return fmt.Errorf("llama: не удалось загрузить модель %q: %w", s.modelPath, err)
	}

	s.model = m
	return nil
}

func (s *LlamaService) CheckConnection(ctx context.Context) (bool, error) {
	if err := s.ensureModel(); err != nil {
		return false, err
	}

	return true, nil
}

func (s *LlamaService) GetModels(ctx context.Context) ([]string, error) {
	if s.modelPath == "" {
		return []string{}, nil
	}

	name := filepath.Base(s.modelPath)

	return []string{name}, nil
}

func (s *LlamaService) SendMessage(ctx context.Context, model string, messages []*domain.Message) (chan string, error) {
	if err := s.ensureModel(); err != nil {
		return nil, err
	}

	prompt := buildPrompt(messages)

	out := make(chan string, 32)
	go func() {
		defer close(out)

		s.mu.Lock()
		text, err := s.model.Predict(prompt, s.predictOpts...)
		s.mu.Unlock()
		if err != nil {
			return
		}

		chunkSize := s.chunkSize
		for len(text) > 0 {
			if ctx.Err() != nil {
				return
			}

			n := chunkSize
			if len(text) < n {
				n = len(text)
			}

			chunk := text[:n]
			text = text[n:]

			if strings.TrimSpace(chunk) == "" {
				continue
			}

			select {
			case <-ctx.Done():
				return
			case out <- chunk:
			}
		}
	}()

	return out, nil
}

func buildPrompt(messages []*domain.Message) string {
	var b strings.Builder
	for _, m := range messages {
		role := "User"
		if m.Role == domain.MessageRoleAssistant {
			role = "Assistant"
		}

		b.WriteString(role)
		b.WriteString(": ")
		b.WriteString(m.Content)
		b.WriteString("\n")
	}

	b.WriteString("Assistant: ")

	return b.String()
}
