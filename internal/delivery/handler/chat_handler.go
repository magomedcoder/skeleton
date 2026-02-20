package handler

import (
	"context"
	"strconv"

	"github.com/magomedcoder/legion/api/pb/chatpb"
	"github.com/magomedcoder/legion/api/pb/commonpb"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/delivery/middleware"
	"github.com/magomedcoder/legion/internal/usecase"
	error2 "github.com/magomedcoder/legion/pkg/error"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type ChatHandler struct {
	chatpb.UnimplementedChatServiceServer
	chatUseCase *usecase.ChatUseCase
	authUseCase usecase.TokenValidator
}

func NewChatHandler(chatUseCase *usecase.ChatUseCase, authUseCase usecase.TokenValidator) *ChatHandler {
	return &ChatHandler{
		chatUseCase: chatUseCase,
		authUseCase: authUseCase,
	}
}

func messageToProto(m *domain.Message) *chatpb.Message {
	return &chatpb.Message{
		Id:        m.Id,
		Peer:      &commonpb.Peer{Peer: &commonpb.Peer_UserId{UserId: int64(m.PeerId)}},
		FromPeer:  &commonpb.Peer{Peer: &commonpb.Peer_UserId{UserId: int64(m.FromPeerId)}},
		Content:   m.Content,
		CreatedAt: m.CreatedAt.Unix(),
	}
}

func (h *ChatHandler) getUserID(ctx context.Context) (int, error) {
	session := middleware.GetSession(ctx)
	if session == nil {
		return 0, status.Error(codes.Unauthenticated, "сессия не найдена")
	}
	return session.Uid, nil
}

func (h *ChatHandler) CreateChat(ctx context.Context, req *chatpb.CreateChatRequest) (*chatpb.Chat, error) {
	uid, err := h.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	userId, err := strconv.Atoi(req.UserId)
	if err != nil {
		return nil, error2.ToStatusError(codes.InvalidArgument, err)
	}

	chat, _, err := h.chatUseCase.CreateChat(ctx, uid, userId)
	if err != nil {
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	return chatToProto(chat), nil
}

func chatToProto(ch *domain.Chat) *chatpb.Chat {
	return &chatpb.Chat{
		Peer:      &commonpb.Peer{Peer: &commonpb.Peer_UserId{UserId: int64(ch.PeerId)}},
		UpdatedAt: ch.UpdatedAt.Unix(),
	}
}

func (h *ChatHandler) GetChats(ctx context.Context, req *chatpb.GetChatsRequest) (*chatpb.GetChatsResponse, error) {
	uid, err := h.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	chats, users, err := h.chatUseCase.GetChats(ctx, uid)
	if err != nil {
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	protoChats := make([]*chatpb.Chat, 0, len(chats))
	for _, ch := range chats {
		protoChats = append(protoChats, chatToProto(ch))
	}
	protoUsers := make([]*commonpb.User, 0, len(users))
	for _, u := range users {
		protoUsers = append(protoUsers, &commonpb.User{
			Id:       strconv.Itoa(u.Id),
			Username: u.Username,
			Name:     u.Name,
			Surname:  u.Surname,
			Role:     int32(u.Role),
		})
	}

	return &chatpb.GetChatsResponse{
		Chats: protoChats,
		Users: protoUsers,
	}, nil
}

func (h *ChatHandler) SendMessage(ctx context.Context, req *chatpb.SendMessageRequest) (*chatpb.Message, error) {
	uid, err := h.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	if req.Peer == nil || req.Peer.GetUserId() == 0 {
		return nil, status.Error(codes.InvalidArgument, "peer user_id обязателен")
	}
	peerUserId := int(req.Peer.GetUserId())

	msg, err := h.chatUseCase.SendMessage(ctx, uid, peerUserId, req.Content)
	if err != nil {
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	return messageToProto(msg), nil
}

func (h *ChatHandler) GetHistory(ctx context.Context, req *chatpb.GetHistoryRequest) (*chatpb.GetHistoryResponse, error) {
	uid, err := h.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	if req.Peer == nil || req.Peer.GetUserId() == 0 {
		return nil, status.Error(codes.InvalidArgument, "peer user_id обязателен")
	}
	peerUserId := req.Peer.GetUserId()
	messageId := req.MessageId
	limit := req.Limit
	if limit <= 0 || limit > 100 {
		limit = 50
	}

	msgs, users, err := h.chatUseCase.GetHistory(ctx, uid, peerUserId, messageId, limit)
	if err != nil {
		if err == domain.ErrUnauthorized {
			return nil, status.Error(codes.PermissionDenied, err.Error())
		}
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	protoMsgs := make([]*chatpb.Message, 0, len(msgs))
	for _, m := range msgs {
		protoMsgs = append(protoMsgs, messageToProto(m))
	}
	protoUsers := make([]*commonpb.User, 0, len(users))
	for _, u := range users {
		protoUsers = append(protoUsers, &commonpb.User{
			Id:       strconv.Itoa(u.Id),
			Username: u.Username,
			Name:     u.Name,
			Surname:  u.Surname,
			Role:     int32(u.Role),
		})
	}

	return &chatpb.GetHistoryResponse{
		Messages: protoMsgs,
		Users:    protoUsers,
	}, nil
}

func (h *ChatHandler) DeleteMessages(ctx context.Context, req *chatpb.DeleteMessagesRequest) (*chatpb.DeleteMessagesResponse, error) {
	uid, err := h.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	if len(req.MessageIds) == 0 {
		return nil, status.Error(codes.InvalidArgument, "message_ids обязателен")
	}

	revoke := req.Revoke
	if err := h.chatUseCase.DeleteMessages(ctx, uid, req.MessageIds, revoke); err != nil {
		if err == domain.ErrUnauthorized {
			return nil, status.Error(codes.PermissionDenied, err.Error())
		}

		return nil, error2.ToStatusError(codes.Internal, err)
	}

	return &chatpb.DeleteMessagesResponse{}, nil
}
