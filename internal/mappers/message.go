package mappers

import (
	"time"

	"github.com/magomedcoder/legion/api/pb/chatpb"
	"github.com/magomedcoder/legion/internal/domain"
)

func MessageToProto(msg *domain.Message) *chatpb.ChatMessage {
	if msg == nil {
		return nil
	}

	return &chatpb.ChatMessage{
		Id:        msg.Id,
		Content:   msg.Content,
		Role:      domain.ToProtoRole(msg.Role),
		CreatedAt: msg.CreatedAt.Unix(),
	}
}

func MessageFromProto(proto *chatpb.ChatMessage, sessionID string) *domain.Message {
	if proto == nil {
		return nil
	}

	return &domain.Message{
		Id:        proto.Id,
		SessionId: sessionID,
		Content:   proto.Content,
		Role:      domain.FromProtoRole(proto.Role),
		CreatedAt: time.Unix(proto.CreatedAt, 0),
		UpdatedAt: time.Unix(proto.CreatedAt, 0),
	}
}

func MessagesFromProto(protos []*chatpb.ChatMessage, sessionID string) []*domain.Message {
	if len(protos) == 0 {
		return nil
	}

	out := make([]*domain.Message, len(protos))
	for i, p := range protos {
		out[i] = MessageFromProto(p, sessionID)
	}

	return out
}
