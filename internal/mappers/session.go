package mappers

import (
	"github.com/magomedcoder/skeleton/api/pb/chatpb"
	"github.com/magomedcoder/skeleton/internal/domain"
)

func SessionToProto(session *domain.ChatSession) *chatpb.ChatSession {
	if session == nil {
		return nil
	}

	return &chatpb.ChatSession{
		Id:        session.Id,
		Title:     session.Title,
		Model:     session.Model,
		CreatedAt: session.CreatedAt.Unix(),
		UpdatedAt: session.UpdatedAt.Unix(),
	}
}
