package mappers

import (
	"testing"
	"time"

	"github.com/magomedcoder/skeleton/api/pb/aichatpb"
	"github.com/magomedcoder/skeleton/internal/domain"
)

func TestMessageToProto_nil(t *testing.T) {
	if got := AIMessageToProto(nil); got != nil {
		t.Errorf("MessageToProto(nil) = %v, ожидалось nil", got)
	}
}

func TestMessageToProto(t *testing.T) {
	ts := time.Now()
	m := &domain.AIChatMessage{
		Id:        "mid",
		SessionId: "sid",
		Content:   "hi",
		Role:      domain.AIChatMessageRoleUser,
		CreatedAt: ts,
		UpdatedAt: ts,
	}

	got := AIMessageToProto(m)
	if got == nil {
		t.Fatal("ожидался непустой результат")
	}

	if got.Id != "mid" || got.Content != "hi" || got.Role != "user" || got.CreatedAt != ts.Unix() {
		t.Errorf("MessageToProto: неверные поля %+v", got)
	}
}

func TestMessageToProto_withAttachment(t *testing.T) {
	m := &domain.AIChatMessage{
		Id:             "m",
		Content:        "x",
		Role:           domain.AIChatMessageRoleUser,
		AttachmentName: "f.txt",
	}
	got := AIMessageToProto(m)
	if got.AttachmentName == nil || *got.AttachmentName != "f.txt" {
		t.Errorf("AttachmentName неверный: %v", got.AttachmentName)
	}
}

func TestMessageFromProto_nil(t *testing.T) {
	if got := AIMessageFromProto(nil, "s"); got != nil {
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
	got := AIMessageFromProto(p, "sid")
	if got == nil {
		t.Fatal("ожидался непустой результат")
	}

	if got.Id != "m" || got.SessionId != "sid" || got.Content != "hi" || got.Role != domain.AIChatMessageRoleUser {
		t.Errorf("MessageFromProto: неверные поля %+v", got)
	}
}

func TestMessagesFromProto_empty(t *testing.T) {
	if got := AIMessagesFromProto(nil, "s"); got != nil {
		t.Errorf("MessagesFromProto(nil) = %v, ожидалось nil", got)
	}

	if got := AIMessagesFromProto([]*aichatpb.ChatMessage{}, "s"); got != nil {
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
	got := AIMessagesFromProto([]*aichatpb.ChatMessage{p}, "sid")
	if len(got) != 1 || got[0].Content != "a" {
		t.Errorf("MessagesFromProto: неверный результат %+v", got)
	}
}
