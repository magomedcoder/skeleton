//go:build llama
// +build llama

package service

import (
	"context"
	"fmt"
	llama "github.com/magomedcoder/legion/pkg/llama.cpp"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"

	"github.com/magomedcoder/legion/internal/domain"
)

const defaultChunkSize = 128

type LlamaService struct {
	modelsDir        string
	currentModelName string
	chunkSize        int
	predictOpts      []llama.PredictOption
	mu               sync.Mutex
	model            *llama.LLama
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
	modelsDir := modelPath
	if modelPath != "" {
		if info, err := os.Stat(modelPath); err == nil && !info.IsDir() {
			modelsDir = filepath.Dir(modelPath)
		}
	}

	s := &LlamaService{
		modelsDir: modelsDir,
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

func (s *LlamaService) ensureModel(modelName string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.modelsDir == "" {
		return fmt.Errorf("llama: путь к папке с моделями не задан")
	}
	if modelName == "" {
		return fmt.Errorf("llama: укажите модель (доступные: %s)", strings.Join(s.modelNamesLocked(), ", "))
	}

	fullPath := filepath.Join(s.modelsDir, modelName)
	if s.model != nil && s.currentModelName == modelName {
		return nil
	}

	if s.model != nil {
		s.model.Free()
		s.model = nil
		s.currentModelName = ""
	}

	m, err := llama.New(fullPath)
	if err != nil {
		return fmt.Errorf("llama: не удалось загрузить модель %q: %w", modelName, err)
	}

	s.model = m
	s.currentModelName = modelName
	return nil
}

func (s *LlamaService) modelNamesLocked() []string {
	if s.modelsDir == "" {
		return nil
	}

	entries, err := os.ReadDir(s.modelsDir)
	if err != nil {
		return nil
	}

	var names []string
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		ext := strings.ToLower(filepath.Ext(e.Name()))
		if ext == ".gguf" {
			names = append(names, e.Name())
		}
	}

	sort.Strings(names)

	return names
}

func (s *LlamaService) CheckConnection(ctx context.Context) (bool, error) {
	models, err := s.GetModels(ctx)
	if err != nil || len(models) == 0 {
		return false, fmt.Errorf("llama: нет моделей в папке %q", s.modelsDir)
	}

	if err := s.ensureModel(models[0]); err != nil {
		return false, err
	}

	return true, nil
}

func (s *LlamaService) GetModels(ctx context.Context) ([]string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.modelNamesLocked(), nil
}

func (s *LlamaService) SendMessage(ctx context.Context, model string, messages []*domain.Message) (chan string, error) {
	if err := s.ensureModel(model); err != nil {
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
