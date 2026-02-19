package usecase

import (
	"context"
	"testing"

	"github.com/magomedcoder/legion/internal/domain"
)

type mockLLMProvider struct {
	getModels func(context.Context) ([]string, error)
}

func (m *mockLLMProvider) GetModels(ctx context.Context) ([]string, error) {
	if m.getModels != nil {
		return m.getModels(ctx)
	}

	return nil, nil
}

func (m *mockLLMProvider) CheckConnection(context.Context) (bool, error) {
	return true, nil
}

func (m *mockLLMProvider) SendMessage(context.Context, string, string, []*domain.AIChatMessage) (chan string, error) {
	ch := make(chan string, 1)
	ch <- ""
	close(ch)
	return ch, nil
}

func TestAIChatUseCase_GetModels(t *testing.T) {
	want := []string{"model1", "model2"}
	llm := &mockLLMProvider{
		getModels: func(context.Context) ([]string, error) { return want, nil },
	}

	uc := NewAIChatUseCase(nil, nil, nil, llm, nil)
	got, err := uc.GetModels(context.Background())
	if err != nil {
		t.Fatalf("GetModels: %v", err)
	}

	if len(got) != 2 || got[0] != "model1" || got[1] != "model2" {
		t.Errorf("GetModels: получено %v", got)
	}
}
