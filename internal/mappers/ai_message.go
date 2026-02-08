package mappers

import (
	"github.com/magomedcoder/skeleton/api/pb/aichatpb"
	"github.com/magomedcoder/skeleton/internal/domain"
	"time"
)

func AIMessageToProto(msg *domain.AIChatMessage) *aichatpb.ChatMessage {
	if msg == nil {
		return nil
	}

	p := &aichatpb.ChatMessage{
		Id:        msg.Id,
		Content:   msg.Content,
		Role:      domain.AIToProtoRole(msg.Role),
		CreatedAt: msg.CreatedAt.Unix(),
	}
	if msg.AttachmentName != "" {
		p.AttachmentName = &msg.AttachmentName
	}

	return p
}

func AIMessageFromProto(proto *aichatpb.ChatMessage, sessionID string) *domain.AIChatMessage {
	if proto == nil {
		return nil
	}

	msg := &domain.AIChatMessage{
		Id:        proto.Id,
		SessionId: sessionID,
		Content:   proto.Content,
		Role:      domain.AIFromProtoRole(proto.Role),
		CreatedAt: time.Unix(proto.CreatedAt, 0),
		UpdatedAt: time.Unix(proto.CreatedAt, 0),
	}
	if proto.AttachmentName != nil {
		msg.AttachmentName = *proto.AttachmentName
	}

	return msg
}

func AIMessagesFromProto(protos []*aichatpb.ChatMessage, sessionID string) []*domain.AIChatMessage {
	if len(protos) == 0 {
		return nil
	}

	out := make([]*domain.AIChatMessage, len(protos))
	for i, p := range protos {
		out[i] = AIMessageFromProto(p, sessionID)
	}

	return out
}
