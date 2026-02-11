package mappers

import (
	"testing"
	"time"

	"github.com/magomedcoder/legion/internal/domain"
)

func TestAISessionToProto_nil(t *testing.T) {
	if got := AIChatSessionToProto(nil); got != nil {
		t.Errorf("SessionToProto(nil) = %v, ожидалось nil", got)
	}
}

func TestAISessionToProto(t *testing.T) {
	ts := time.Now()
	s := &domain.AIChatSession{
		Id:        "sid",
		Title:     "t",
		Model:     "m",
		UserId:    1,
		CreatedAt: ts,
		UpdatedAt: ts,
	}
	got := AIChatSessionToProto(s)
	if got == nil {
		t.Fatal("ожидался непустой результат")
	}

	if got.Id != "sid" || got.Title != "t" || got.Model != "m" || got.CreatedAt != ts.Unix() || got.UpdatedAt != ts.Unix() {
		t.Errorf("SessionToProto: неверные поля %+v", got)
	}
}
