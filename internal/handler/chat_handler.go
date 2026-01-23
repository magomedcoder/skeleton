package handler

import (
	"context"
	"strings"
	"time"

	"github.com/magomedcoder/legion/api/pb/chatpb"
	"github.com/magomedcoder/legion/internal/usecase"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

type ChatHandler struct {
	chatpb.UnimplementedChatServiceServer
	chatUseCase *usecase.ChatUseCase
	authUseCase *usecase.AuthUseCase
}

func NewChatHandler(chatUseCase *usecase.ChatUseCase, authUseCase *usecase.AuthUseCase) *ChatHandler {
	return &ChatHandler{
		chatUseCase: chatUseCase,
		authUseCase: authUseCase,
	}
}

func (h *ChatHandler) getUserID(ctx context.Context) (int, error) {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return 0, status.Error(codes.Unauthenticated, "метаданные не предоставлены")
	}

	authHeaders := md.Get("authorization")
	if len(authHeaders) == 0 {
		return 0, status.Error(codes.Unauthenticated, "заголовок авторизации не предоставлен")
	}

	authHeader := authHeaders[0]
	if !strings.HasPrefix(authHeader, "Bearer ") {
		return 0, status.Error(codes.Unauthenticated, "неверный формат заголовка авторизации")
	}

	token := strings.TrimPrefix(authHeader, "Bearer ")
	user, err := h.authUseCase.ValidateToken(ctx, token)
	if err != nil {
		return 0, status.Error(codes.Unauthenticated, err.Error())
	}

	return user.Id, nil
}

func (h *ChatHandler) SendMessage(req *chatpb.SendMessageRequest, stream chatpb.ChatService_SendMessageServer) error {
	ctx := stream.Context()
	userID, err := h.getUserID(ctx)
	if err != nil {
		return err
	}

	if len(req.Messages) == 0 {
		return status.Error(codes.InvalidArgument, "сообщения не предоставлены")
	}

	lastMessage := req.Messages[len(req.Messages)-1]
	userMessage := lastMessage.Content

	responseChan, messageID, err := h.chatUseCase.SendMessage(ctx, userID, req.SessionId, userMessage)
	if err != nil {
		return status.Error(codes.Internal, err.Error())
	}

	createdAt := time.Now().Unix()

	for chunk := range responseChan {
		err := stream.Send(&chatpb.ChatResponse{
			Id:        messageID,
			Content:   chunk,
			Role:      "assistant",
			CreatedAt: createdAt,
			Done:      false,
		})
		if err != nil {
			return err
		}
	}

	return stream.Send(&chatpb.ChatResponse{
		Id:        messageID,
		Content:   "",
		Role:      "assistant",
		CreatedAt: createdAt,
		Done:      true,
	})
}

func (h *ChatHandler) CreateSession(ctx context.Context, req *chatpb.CreateSessionRequest) (*chatpb.ChatSession, error) {
	userID, err := h.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	session, err := h.chatUseCase.CreateSession(ctx, userID, req.Title)
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}

	return h.sessionToProto(session), nil
}

func (h *ChatHandler) GetSession(ctx context.Context, req *chatpb.GetSessionRequest) (*chatpb.ChatSession, error) {
	userID, err := h.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	session, err := h.chatUseCase.GetSession(ctx, userID, req.SessionId)
	if err != nil {
		return nil, status.Error(codes.NotFound, err.Error())
	}

	return h.sessionToProto(session), nil
}

func (h *ChatHandler) ListSessions(ctx context.Context, req *chatpb.ListSessionsRequest) (*chatpb.ListSessionsResponse, error) {
	userID, err := h.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	page := req.Page
	if page == 0 {
		page = 1
	}
	pageSize := req.PageSize
	if pageSize == 0 {
		pageSize = 20
	}

	sessions, total, err := h.chatUseCase.ListSessions(ctx, userID, page, pageSize)
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}

	protoSessions := make([]*chatpb.ChatSession, len(sessions))
	for i, session := range sessions {
		protoSessions[i] = h.sessionToProto(session)
	}

	return &chatpb.ListSessionsResponse{
		Sessions: protoSessions,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

func (h *ChatHandler) GetSessionMessages(ctx context.Context, req *chatpb.GetSessionMessagesRequest) (*chatpb.GetSessionMessagesResponse, error) {
	userID, err := h.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	page := req.Page
	if page == 0 {
		page = 1
	}
	pageSize := req.PageSize
	if pageSize == 0 {
		pageSize = 50
	}

	messages, total, err := h.chatUseCase.GetSessionMessages(ctx, userID, req.SessionId, page, pageSize)
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}

	protoMessages := make([]*chatpb.ChatMessage, len(messages))
	for i, msg := range messages {
		protoMessages[i] = h.messageToProto(msg)
	}

	return &chatpb.GetSessionMessagesResponse{
		Messages: protoMessages,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

func (h *ChatHandler) DeleteSession(ctx context.Context, req *chatpb.DeleteSessionRequest) (*chatpb.Empty, error) {
	userID, err := h.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	if err := h.chatUseCase.DeleteSession(ctx, userID, req.SessionId); err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}

	return &chatpb.Empty{}, nil
}

func (h *ChatHandler) UpdateSessionTitle(ctx context.Context, req *chatpb.UpdateSessionTitleRequest) (*chatpb.ChatSession, error) {
	userID, err := h.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	session, err := h.chatUseCase.UpdateSessionTitle(ctx, userID, req.SessionId, req.Title)
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}

	return h.sessionToProto(session), nil
}

func (h *ChatHandler) CheckConnection(ctx context.Context, req *chatpb.Empty) (*chatpb.ConnectionResponse, error) {
	return &chatpb.ConnectionResponse{IsConnected: true}, nil
}
