package provider

import (
	"context"
	"errors"
	"testing"

	"github.com/magomedcoder/skeleton/internal/domain"
)

type mockTextBackend struct {
	checkConn func(context.Context) (bool, error)
	getModels func(context.Context) ([]string, error)
	sendMsg   func(context.Context, string, []*domain.Message) (chan string, error)
}

func (m *mockTextBackend) CheckConnection(ctx context.Context) (bool, error) {
	if m.checkConn != nil {
		return m.checkConn(ctx)
	}

	return true, nil
}

func (m *mockTextBackend) GetModels(ctx context.Context) ([]string, error) {
	if m.getModels != nil {
		return m.getModels(ctx)
	}

	return nil, nil
}

func (m *mockTextBackend) SendMessage(ctx context.Context, model string, messages []*domain.Message) (chan string, error) {
	if m.sendMsg != nil {
		return m.sendMsg(ctx, model, messages)
	}

	ch := make(chan string)
	close(ch)
	return ch, nil
}

func TestNewText(t *testing.T) {
	backend := &mockTextBackend{}
	tp := NewText(backend)
	if tp == nil {
		t.Fatal("NewText не должен возвращать nil")
	}
}

func TestText_CheckConnection(t *testing.T) {
	backend := &mockTextBackend{checkConn: func(context.Context) (bool, error) {
		return true, nil
	}}
	tp := NewText(backend)
	ok, err := tp.CheckConnection(context.Background())
	if err != nil {
		t.Fatalf("CheckConnection: %v", err)
	}

	if !ok {
		t.Error("ожидалось true")
	}
}

func TestText_GetModels(t *testing.T) {
	backend := &mockTextBackend{
		getModels: func(context.Context) ([]string, error) {
			return []string{"m1"}, nil
		},
	}
	tp := NewText(backend)
	models, err := tp.GetModels(context.Background())
	if err != nil {
		t.Fatalf("GetModels: %v", err)
	}

	if len(models) != 1 || models[0] != "m1" {
		t.Errorf("получено %v", models)
	}
}

func TestText_GetModels_backendError(t *testing.T) {
	backend := &mockTextBackend{
		getModels: func(context.Context) ([]string, error) {
			return nil, errors.New("ошибка")
		},
	}
	tp := NewText(backend)

	_, err := tp.GetModels(context.Background())
	if err == nil {
		t.Error("ожидалась ошибка")
	}
}
