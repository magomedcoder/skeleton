package mappers

import (
	"testing"
	"time"

	"github.com/magomedcoder/skeleton/api/pb/aichatpb"
	"github.com/magomedcoder/skeleton/internal/domain"
)

func TestMessageToProto_nil(t *testing.T) {
	if got := MessageToProto(nil); got != nil {
		t.Errorf("MessageToProto(nil) = %v, ожидалось nil", got)
	}
}

func TestMessageToProto(t *testing.T) {
	ts := time.Now()
	m := &domain.Message{
		Id:        "mid",
		SessionId: "sid",
		Content:   "hi",
		Role:      domain.MessageRoleUser,
		CreatedAt: ts,
		UpdatedAt: ts,
	}

	got := MessageToProto(m)
	if got == nil {
		t.Fatal("ожидался непустой результат")
	}

	if got.Id != "mid" || got.Content != "hi" || got.Role != "user" || got.CreatedAt != ts.Unix() {
		t.Errorf("MessageToProto: неверные поля %+v", got)
	}
}

func TestMessageToProto_withAttachment(t *testing.T) {
	m := &domain.Message{
		Id:             "m",
		Content:        "x",
		Role:           domain.MessageRoleUser,
		AttachmentName: "f.txt",
	}
	got := MessageToProto(m)
	if got.AttachmentName == nil || *got.AttachmentName != "f.txt" {
		t.Errorf("AttachmentName неверный: %v", got.AttachmentName)
	}
}

func TestMessageFromProto_nil(t *testing.T) {
	if got := MessageFromProto(nil, "s"); got != nil {
		t.Errorf("MessageFromProto(nil) = %v, ожидалось nil", got)
	}
}

func TestMessageFromProto(t *testing.T) {
	ts := int64(12345)
	p := &aichatpb.ChatMessage{
		Id:        "m",
		Content:   "hi",
		Role:      "user",
		CreatedAt: ts,
	}
	got := MessageFromProto(p, "sid")
	if got == nil {
		t.Fatal("ожидался непустой результат")
	}

	if got.Id != "m" || got.SessionId != "sid" || got.Content != "hi" || got.Role != domain.MessageRoleUser {
		t.Errorf("MessageFromProto: неверные поля %+v", got)
	}
}

func TestMessagesFromProto_empty(t *testing.T) {
	if got := MessagesFromProto(nil, "s"); got != nil {
		t.Errorf("MessagesFromProto(nil) = %v, ожидалось nil", got)
	}

	if got := MessagesFromProto([]*aichatpb.ChatMessage{}, "s"); got != nil {
		t.Errorf("MessagesFromProto(пустой слайс) = %v, ожидалось nil", got)
	}
}

func TestMessagesFromProto(t *testing.T) {
	p := &aichatpb.ChatMessage{
		Id:        "1",
		Content:   "a",
		Role:      "user",
		CreatedAt: 1,
	}
	got := MessagesFromProto([]*aichatpb.ChatMessage{p}, "sid")
	if len(got) != 1 || got[0].Content != "a" {
		t.Errorf("MessagesFromProto: неверный результат %+v", got)
	}
}
