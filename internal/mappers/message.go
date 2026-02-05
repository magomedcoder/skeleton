package mappers

import (
	"time"

	"github.com/magomedcoder/skeleton/api/pb/chatpb"
	"github.com/magomedcoder/skeleton/internal/domain"
)

func MessageToProto(msg *domain.Message) *chatpb.ChatMessage {
	if msg == nil {
		return nil
	}

	p := &chatpb.ChatMessage{
		Id:        msg.Id,
		Content:   msg.Content,
		Role:      domain.ToProtoRole(msg.Role),
		CreatedAt: msg.CreatedAt.Unix(),
	}
	if msg.AttachmentName != "" {
		p.AttachmentName = &msg.AttachmentName
	}

	return p
}

func MessageFromProto(proto *chatpb.ChatMessage, sessionID string) *domain.Message {
	if proto == nil {
		return nil
	}

	msg := &domain.Message{
		Id:        proto.Id,
		SessionId: sessionID,
		Content:   proto.Content,
		Role:      domain.FromProtoRole(proto.Role),
		CreatedAt: time.Unix(proto.CreatedAt, 0),
		UpdatedAt: time.Unix(proto.CreatedAt, 0),
	}
	if proto.AttachmentName != nil {
		msg.AttachmentName = *proto.AttachmentName
	}

	return msg
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
