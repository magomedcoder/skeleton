package domain

import (
	"testing"
	"time"
)

func TestErrUnauthorized(t *testing.T) {
	if ErrUnauthorized == nil {
		t.Fatal("ErrUnauthorized не должен быть nil")
	}

	if ErrUnauthorized.Error() == "" {
		t.Error("ErrUnauthorized должен содержать сообщение")
	}
}

func TestNewToken(t *testing.T) {
	exp := time.Now().Add(time.Hour)
	tok := NewToken(1, "secret", TokenTypeAccess, exp)
	if tok.UserId != 1 || tok.Token != "secret" || tok.Type != TokenTypeAccess {
		t.Errorf("NewToken: неверные поля %+v", tok)
	}

	if tok.ExpiresAt.Before(exp) || tok.ExpiresAt.After(exp.Add(time.Second)) {
		t.Error("ExpiresAt не совпадает")
	}
}

func TestToken_IsExpired(t *testing.T) {
	past := time.Now().Add(-time.Hour)
	future := time.Now().Add(time.Hour)
	if !NewToken(1, "a", TokenTypeAccess, past).IsExpired() {
		t.Error("токен в прошлом должен считаться просроченным")
	}

	if NewToken(1, "a", TokenTypeAccess, future).IsExpired() {
		t.Error("токен в будущем не должен быть просрочен")
	}
}

func TestFromProtoRole_ToProtoRole(t *testing.T) {
	tests := []struct {
		proto string
		want  AIChatMessageRole
	}{
		{"system", AIChatMessageRoleSystem},
		{"user", AIChatMessageRoleUser},
		{"assistant", AIChatMessageRoleAssistant},
		{"unknown", AIChatMessageRoleUser},
		{"", AIChatMessageRoleUser},
	}
	for _, tt := range tests {
		got := AIFromProtoRole(tt.proto)
		if got != tt.want {
			t.Errorf("FromProtoRole(%q) = %v, ожидалось %v", tt.proto, got, tt.want)
		}
		if back := AIToProtoRole(got); back != string(tt.want) && tt.proto != "unknown" && tt.proto != "" {
			if (tt.proto == "unknown" || tt.proto == "") && back == "user" {
				continue
			}
			t.Errorf("ToProtoRole(FromProtoRole(%q)) = %q", tt.proto, back)
		}
	}
}

func TestMessage_ToMap(t *testing.T) {
	m := &AIChatMessage{
		Content: "hi",
		Role:    AIChatMessageRoleUser,
	}
	out := m.AIToMap()
	if out["role"] != "user" || out["content"] != "hi" {
		t.Errorf("ToMap() вернул %v", out)
	}
}

func TestNewMessage(t *testing.T) {
	m := NewAIChatMessage("sess1", "text", AIChatMessageRoleUser)
	if m.SessionId != "sess1" || m.Content != "text" || m.Role != AIChatMessageRoleUser || m.Id == "" {
		t.Errorf("NewMessage: неверные поля %+v", m)
	}
}

func TestNewMessageWithAttachment(t *testing.T) {
	m := NewAIChatMessageWithAttachment("sess1", "text", AIChatMessageRoleAssistant, "file.txt")
	if m.AttachmentName != "file.txt" || m.Role != AIChatMessageRoleAssistant {
		t.Errorf("NewMessageWithAttachment: неверные поля %+v", m)
	}
}

func TestNewChatSession(t *testing.T) {
	s := NewAIChatSession(1, "title", "model1")
	if s.UserId != 1 || s.Title != "title" || s.Model != "model1" || s.Id == "" {
		t.Errorf("NewChatSession: неверные поля %+v", s)
	}
}

func TestNewFile(t *testing.T) {
	f := NewFile("doc.pdf", "application/pdf", 1024, "/store/abc")
	if f.Filename != "doc.pdf" || f.MimeType != "application/pdf" || f.Size != 1024 || f.StoragePath != "/store/abc" || f.Id == "" {
		t.Errorf("NewFile: неверные поля %+v", f)
	}
}
