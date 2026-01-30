package mappers

import (
	"github.com/magomedcoder/legion/api/pb/chatpb"
	"github.com/magomedcoder/legion/internal/domain"
)

func SessionToProto(session *domain.ChatSession) *chatpb.ChatSession {
	if session == nil {
		return nil
	}

	return &chatpb.ChatSession{
		Id:        session.Id,
		Title:     session.Title,
		CreatedAt: session.CreatedAt.Unix(),
		UpdatedAt: session.UpdatedAt.Unix(),
	}
}
