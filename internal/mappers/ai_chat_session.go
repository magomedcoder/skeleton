package mappers

import (
	"github.com/magomedcoder/skeleton/api/pb/aichatpb"
	"github.com/magomedcoder/skeleton/internal/domain"
)

func AIChatSessionToProto(session *domain.AIChatSession) *aichatpb.ChatSession {
	if session == nil {
		return nil
	}

	return &aichatpb.ChatSession{
		Id:        session.Id,
		Title:     session.Title,
		Model:     session.Model,
		CreatedAt: session.CreatedAt.Unix(),
		UpdatedAt: session.UpdatedAt.Unix(),
	}
}
