package domain

type MessageRole string

const (
	MessageRoleUser      MessageRole = "user"
	MessageRoleAssistant MessageRole = "assistant"
)

func (m *Message) ToMap() map[string]interface{} {
	return map[string]interface{}{
		"role":    string(m.Role),
		"content": m.Content,
	}
}

func FromProtoRole(role string) MessageRole {
	switch role {
	case "user":
		return MessageRoleUser
	case "assistant":
		return MessageRoleAssistant
	default:
		return MessageRoleUser
	}
}

func ToProtoRole(role MessageRole) string {
	return string(role)
}
