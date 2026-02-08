package usecase

import (
	"context"
	"testing"

	"github.com/magomedcoder/legion/api/pb/editorpb"
	"github.com/magomedcoder/legion/internal/domain"
)

type mockEditorLLM struct {
	sendMessage func(context.Context, string, string, []*domain.AIChatMessage) (chan string, error)
}

func (m *mockEditorLLM) GetModels(context.Context) ([]string, error) {
	return nil, nil
}

func (m *mockEditorLLM) CheckConnection(context.Context) (bool, error) {
	return true, nil
}

func (m *mockEditorLLM) SendMessage(ctx context.Context, sessionID string, model string, messages []*domain.AIChatMessage) (chan string, error) {
	if m.sendMessage != nil {
		return m.sendMessage(ctx, sessionID, model, messages)
	}

	ch := make(chan string, 1)
	ch <- "transformed"
	close(ch)
	return ch, nil
}

func TestEditorUseCase_Transform_emptyText(t *testing.T) {
	uc := NewEditorUseCase(&mockEditorLLM{})
	_, err := uc.Transform(context.Background(), "m", "", editorpb.TransformType_TRANSFORM_TYPE_IMPROVE, false)
	if err == nil {
		t.Fatal("ожидалась ошибка для пустого текста")
	}

	if err.Error() != "пустой текст" {
		t.Errorf("получено %q", err.Error())
	}
}

func TestEditorUseCase_Transform_success(t *testing.T) {
	uc := NewEditorUseCase(&mockEditorLLM{})
	out, err := uc.Transform(context.Background(), "m", "привет", editorpb.TransformType_TRANSFORM_TYPE_IMPROVE, false)
	if err != nil {
		t.Fatalf("Transform: %v", err)
	}

	if out != "transformed" {
		t.Errorf("получено %q", out)
	}
}
