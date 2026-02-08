//go:build !llama

package service

import (
	"context"
	"testing"

	"github.com/magomedcoder/skeleton/internal/domain"
)

func TestNewLlamaService_stub(t *testing.T) {
	svc := NewLlamaService("")
	if svc == nil {
		t.Fatal("NewLlamaService не должен возвращать nil")
	}
}

func TestLlamaService_stub_CheckConnection(t *testing.T) {
	svc := NewLlamaService("/path")
	ok, err := svc.CheckConnection(context.Background())
	if err == nil {
		t.Error("ожидалась ошибка (llama отключена)")
	}

	if ok {
		t.Error("ожидалось false")
	}
}

func TestLlamaService_stub_GetModels(t *testing.T) {
	svc := NewLlamaService("/path")
	models, err := svc.GetModels(context.Background())
	if err == nil {
		t.Error("ожидалась ошибка (llama отключена)")
	}

	if models != nil {
		t.Error("ожидалось nil")
	}
}

func TestLlamaService_stub_SendMessage(t *testing.T) {
	svc := NewLlamaService("/path")
	ch, err := svc.SendMessage(context.Background(), "m", []*domain.Message{})
	if err == nil {
		t.Error("ожидалась ошибка (llama отключена)")
	}

	if ch == nil {
		t.Error("канал не должен быть nil")
	}

	if _, open := <-ch; open {
		t.Error("канал должен быть закрыт")
	}
}
