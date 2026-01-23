package handler

import (
	"github.com/magomedcoder/legion/api/pb/chatpb"
	"github.com/magomedcoder/legion/api/pb/commonpb"
	"github.com/magomedcoder/legion/internal/domain"
	"strconv"
)

func (a *AuthHandler) userToProto(user *domain.User) *commonpb.User {
	return &commonpb.User{
		Id:    strconv.Itoa(user.Id),
		Email: user.Email,
		Name:  user.Name,
	}
}

func (h *ChatHandler) sessionToProto(session *domain.ChatSession) *chatpb.ChatSession {
	return &chatpb.ChatSession{
		Id:        session.Id,
		Title:     session.Title,
		CreatedAt: session.CreatedAt.Unix(),
		UpdatedAt: session.UpdatedAt.Unix(),
	}
}

func (h *ChatHandler) messageToProto(msg *domain.Message) *chatpb.ChatMessage {
	return &chatpb.ChatMessage{
		Id:        msg.Id,
		Content:   msg.Content,
		Role:      domain.ToProtoRole(msg.Role),
		CreatedAt: msg.CreatedAt.Unix(),
	}
}
