package handler

import (
	"strconv"

	"github.com/magomedcoder/legion/api/pb/chatpb"
	"github.com/magomedcoder/legion/api/pb/commonpb"
	"github.com/magomedcoder/legion/internal/domain"
)

func userToProto(user *domain.User) *commonpb.User {
	return &commonpb.User{
		Id:       strconv.Itoa(user.Id),
		Username: user.Username,
		Name:     user.Name,
		Surname:  user.Surname,
		Role:     int32(user.Role),
	}
}

func (c *ChatHandler) sessionToProto(session *domain.ChatSession) *chatpb.ChatSession {
	return &chatpb.ChatSession{
		Id:        session.Id,
		Title:     session.Title,
		CreatedAt: session.CreatedAt.Unix(),
		UpdatedAt: session.UpdatedAt.Unix(),
	}
}

func (c *ChatHandler) messageToProto(msg *domain.Message) *chatpb.ChatMessage {
	return &chatpb.ChatMessage{
		Id:        msg.Id,
		Content:   msg.Content,
		Role:      domain.ToProtoRole(msg.Role),
		CreatedAt: msg.CreatedAt.Unix(),
	}
}
