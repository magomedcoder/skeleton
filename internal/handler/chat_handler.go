package handler

import (
	"context"
	"time"

	"github.com/magomedcoder/legion/api/pb/chatpb"
	"github.com/magomedcoder/legion/internal/mappers"
	"github.com/magomedcoder/legion/internal/usecase"
	"google.golang.org/grpc/codes"
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

func (c *ChatHandler) getUserID(ctx context.Context) (int, error) {
	user, err := GetUserFromContext(ctx, c.authUseCase)
	if err != nil {
		return 0, err
	}
	return user.Id, nil
}

func (c *ChatHandler) SendMessage(req *chatpb.SendMessageRequest, stream chatpb.ChatService_SendMessageServer) error {
	ctx := stream.Context()
	userID, err := c.getUserID(ctx)
	if err != nil {
		return err
	}

	if len(req.Messages) == 0 {
		return status.Error(codes.InvalidArgument, "сообщения не предоставлены")
	}

	lastMessage := req.Messages[len(req.Messages)-1]
	userMessage := lastMessage.Content

	responseChan, messageId, err := c.chatUseCase.SendMessage(ctx, userID, req.SessionId, req.GetModel(), userMessage)
	if err != nil {
		return ToStatusError(codes.Internal, err)
	}

	createdAt := time.Now().Unix()

	for chunk := range responseChan {
		err := stream.Send(&chatpb.ChatResponse{
			Id:        messageId,
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
		Id:        messageId,
		Content:   "",
		Role:      "assistant",
		CreatedAt: createdAt,
		Done:      true,
	})
}

func (c *ChatHandler) CreateSession(ctx context.Context, req *chatpb.CreateSessionRequest) (*chatpb.ChatSession, error) {
	userID, err := c.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	session, err := c.chatUseCase.CreateSession(ctx, userID, req.GetTitle(), req.GetModel())
	if err != nil {
		return nil, ToStatusError(codes.Internal, err)
	}

	return mappers.SessionToProto(session), nil
}

func (c *ChatHandler) GetSession(ctx context.Context, req *chatpb.GetSessionRequest) (*chatpb.ChatSession, error) {
	userID, err := c.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	session, err := c.chatUseCase.GetSession(ctx, userID, req.SessionId)
	if err != nil {
		return nil, ToStatusError(codes.NotFound, err)
	}

	return mappers.SessionToProto(session), nil
}

func (c *ChatHandler) GetSessions(ctx context.Context, req *chatpb.GetSessionsRequest) (*chatpb.GetSessionsResponse, error) {
	userID, err := c.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	page, pageSize := normalizePagination(req.Page, req.PageSize, 20)

	sessions, total, err := c.chatUseCase.GetSessions(ctx, userID, page, pageSize)
	if err != nil {
		return nil, ToStatusError(codes.Internal, err)
	}

	protoSessions := make([]*chatpb.ChatSession, len(sessions))
	for i, session := range sessions {
		protoSessions[i] = mappers.SessionToProto(session)
	}

	return &chatpb.GetSessionsResponse{
		Sessions: protoSessions,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

func (c *ChatHandler) GetSessionMessages(ctx context.Context, req *chatpb.GetSessionMessagesRequest) (*chatpb.GetSessionMessagesResponse, error) {
	userID, err := c.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	page, pageSize := normalizePagination(req.Page, req.PageSize, 50)

	messages, total, err := c.chatUseCase.GetSessionMessages(ctx, userID, req.SessionId, page, pageSize)
	if err != nil {
		return nil, ToStatusError(codes.Internal, err)
	}

	protoMessages := make([]*chatpb.ChatMessage, len(messages))
	for i, msg := range messages {
		protoMessages[i] = mappers.MessageToProto(msg)
	}

	return &chatpb.GetSessionMessagesResponse{
		Messages: protoMessages,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

func (c *ChatHandler) DeleteSession(ctx context.Context, req *chatpb.DeleteSessionRequest) (*chatpb.Empty, error) {
	userID, err := c.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	if err := c.chatUseCase.DeleteSession(ctx, userID, req.SessionId); err != nil {
		return nil, ToStatusError(codes.Internal, err)
	}

	return &chatpb.Empty{}, nil
}

func (c *ChatHandler) UpdateSessionTitle(ctx context.Context, req *chatpb.UpdateSessionTitleRequest) (*chatpb.ChatSession, error) {
	userID, err := c.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	session, err := c.chatUseCase.UpdateSessionTitle(ctx, userID, req.SessionId, req.Title)
	if err != nil {
		return nil, ToStatusError(codes.Internal, err)
	}

	return mappers.SessionToProto(session), nil
}

func (c *ChatHandler) UpdateSessionModel(ctx context.Context, req *chatpb.UpdateSessionModelRequest) (*chatpb.ChatSession, error) {
	userID, err := c.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	session, err := c.chatUseCase.UpdateSessionModel(ctx, userID, req.SessionId, req.GetModel())
	if err != nil {
		return nil, ToStatusError(codes.Internal, err)
	}

	return mappers.SessionToProto(session), nil
}

func (c *ChatHandler) CheckConnection(ctx context.Context, req *chatpb.Empty) (*chatpb.ConnectionResponse, error) {
	return &chatpb.ConnectionResponse{IsConnected: true}, nil
}

func (c *ChatHandler) GetModels(ctx context.Context, req *chatpb.Empty) (*chatpb.GetModelsResponse, error) {
	models, err := c.chatUseCase.GetModels(ctx)
	if err != nil {
		return nil, ToStatusError(codes.Internal, err)
	}
	return &chatpb.GetModelsResponse{Models: models}, nil
}
