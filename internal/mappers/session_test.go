package mappers

import (
	"testing"
	"time"

	"github.com/magomedcoder/skeleton/internal/domain"
)

func TestSessionToProto_nil(t *testing.T) {
	if got := SessionToProto(nil); got != nil {
		t.Errorf("SessionToProto(nil) = %v, ожидалось nil", got)
	}
}

func TestSessionToProto(t *testing.T) {
	ts := time.Now()
	s := &domain.ChatSession{
		Id:        "sid",
		Title:     "t",
		Model:     "m",
		UserId:    1,
		CreatedAt: ts,
		UpdatedAt: ts,
	}
	got := SessionToProto(s)
	if got == nil {
		t.Fatal("ожидался непустой результат")
	}

	if got.Id != "sid" || got.Title != "t" || got.Model != "m" || got.CreatedAt != ts.Unix() || got.UpdatedAt != ts.Unix() {
		t.Errorf("SessionToProto: неверные поля %+v", got)
	}
}
