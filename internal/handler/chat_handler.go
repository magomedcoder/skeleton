package handler

import (
	"context"
	"strconv"

	"github.com/magomedcoder/legion/api/pb/chatpb"
	"github.com/magomedcoder/legion/api/pb/commonpb"
	"github.com/magomedcoder/legion/internal/middleware"
	"github.com/magomedcoder/legion/internal/usecase"
	"github.com/magomedcoder/legion/pkg"
	error2 "github.com/magomedcoder/legion/pkg/error"
	"google.golang.org/grpc/codes"
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

func (h *ChatHandler) getUserID(ctx context.Context) (int, error) {
	user, err := middleware.GetUserFromContext(ctx, h.authUseCase)
	if err != nil {
		return 0, err
	}

	return user.Id, nil
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

	chat, user, err := h.chatUseCase.CreateChat(ctx, uid, userId)
	if err != nil {
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	return &chatpb.Chat{
		Id: strconv.Itoa(chat.Id),
		User: &commonpb.User{
			Id:       strconv.Itoa(user.Id),
			Username: user.Username,
			Name:     user.Name,
			Surname:  user.Surname,
			Role:     int32(user.Role),
		},
		CreatedAt: chat.CreatedAt.Unix(),
	}, nil
}

func (h *ChatHandler) GetChats(ctx context.Context, req *chatpb.GetChatsRequest) (*chatpb.GetChatsResponse, error) {
	uid, err := h.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	page, pageSize := pkg.NormalizePagination(req.Page, req.PageSize, 20)

	chats, usersMap, total, err := h.chatUseCase.GetChats(ctx, uid, page, pageSize)
	if err != nil {
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	protoChats := make([]*chatpb.Chat, 0, len(chats))
	for _, ch := range chats {
		var userId int
		if ch.UserId == uid {
			userId = ch.ReceiverId
		} else {
			userId = ch.UserId
		}
		u := usersMap[userId]
		var protoUser *commonpb.User
		if u != nil {
			protoUser = &commonpb.User{
				Id:       strconv.Itoa(u.Id),
				Username: u.Username,
				Name:     u.Name,
				Surname:  u.Surname,
				Role:     int32(u.Role),
			}
		}

		protoChats = append(protoChats, &chatpb.Chat{
			Id:        strconv.Itoa(ch.Id),
			User:      protoUser,
			CreatedAt: ch.CreatedAt.Unix(),
		})
	}

	return &chatpb.GetChatsResponse{
		Chats:    protoChats,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

func (h *ChatHandler) SendMessage(ctx context.Context, req *chatpb.SendMessageRequest) (*chatpb.Message, error) {
	uid, err := h.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	if req.ChatId == "" {
		return nil, error2.ToStatusError(codes.InvalidArgument, nil)
	}

	chatID, err := strconv.Atoi(req.ChatId)
	if err != nil {
		return nil, error2.ToStatusError(codes.InvalidArgument, err)
	}

	msg, err := h.chatUseCase.SendMessage(ctx, uid, chatID, req.Content)
	if err != nil {
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	return &chatpb.Message{
		Id:        strconv.FormatInt(msg.Id, 10),
		ChatId:    strconv.Itoa(msg.ChatId),
		SenderId:  int32(msg.UserId),
		Content:   msg.Content,
		CreatedAt: msg.CreatedAt.Unix(),
	}, nil
}

func (h *ChatHandler) GetMessages(ctx context.Context, req *chatpb.GetMessagesRequest) (*chatpb.GetMessagesResponse, error) {
	uid, err := h.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	page, pageSize := pkg.NormalizePagination(req.Page, req.PageSize, 50)

	chatID, err := strconv.Atoi(req.ChatId)
	if err != nil {
		return nil, error2.ToStatusError(codes.InvalidArgument, err)
	}

	msgs, total, err := h.chatUseCase.GetMessages(ctx, uid, chatID, page, pageSize)
	if err != nil {
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	protoMsgs := make([]*chatpb.Message, 0, len(msgs))
	for _, m := range msgs {
		protoMsgs = append(protoMsgs, &chatpb.Message{
			Id:        strconv.FormatInt(m.Id, 10),
			ChatId:    strconv.Itoa(m.ChatId),
			SenderId:  int32(m.UserId),
			Content:   m.Content,
			CreatedAt: m.CreatedAt.Unix(),
		})
	}

	return &chatpb.GetMessagesResponse{
		Messages: protoMsgs,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}
