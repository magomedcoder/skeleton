package handler

import (
	"context"
	"github.com/magomedcoder/legion/api/pb/commonpb"
	"github.com/magomedcoder/legion/internal/middleware"
	"github.com/magomedcoder/legion/pkg"
	error2 "github.com/magomedcoder/legion/pkg/error"
	"time"

	"github.com/magomedcoder/legion/api/pb/aichatpb"
	"github.com/magomedcoder/legion/internal/mappers"
	"github.com/magomedcoder/legion/internal/usecase"
	"github.com/magomedcoder/legion/pkg/logger"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type AIChatHandler struct {
	aichatpb.UnimplementedAIChatServiceServer
	aiChatUseCase *usecase.AIChatUseCase
	authUseCase   usecase.TokenValidator
}

func NewAIChatHandler(aiChatUseCase *usecase.AIChatUseCase, authUseCase usecase.TokenValidator) *AIChatHandler {
	return &AIChatHandler{
		aiChatUseCase: aiChatUseCase,
		authUseCase:   authUseCase,
	}
}

func (c *AIChatHandler) getUserID(ctx context.Context) (int, error) {
	user, err := middleware.GetUserFromContext(ctx, c.authUseCase)
	if err != nil {
		return 0, err
	}
	return user.Id, nil
}

func (c *AIChatHandler) SendMessage(req *aichatpb.SendMessageRequest, stream aichatpb.AIChatService_SendMessageServer) error {
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
	attachmentName := ""
	if lastMessage.AttachmentName != nil {
		attachmentName = *lastMessage.AttachmentName
	}
	var attachmentContent []byte
	if lastMessage.AttachmentContent != nil {
		attachmentContent = lastMessage.AttachmentContent
	}

	logger.D("ChatHandler: отправка сообщения в сессию %s", req.SessionId)
	responseChan, messageId, err := c.aiChatUseCase.SendMessage(ctx, userID, req.SessionId, req.GetModel(), userMessage, attachmentName, attachmentContent)
	if err != nil {
		logger.E("ChatHandler: ошибка отправки сообщения: %v", err)
		return error2.ToStatusError(codes.Internal, err)
	}

	createdAt := time.Now().Unix()

	for chunk := range responseChan {
		err := stream.Send(&aichatpb.ChatResponse{
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

	return stream.Send(&aichatpb.ChatResponse{
		Id:        messageId,
		Content:   "",
		Role:      "assistant",
		CreatedAt: createdAt,
		Done:      true,
	})
}

func (c *AIChatHandler) CreateSession(ctx context.Context, req *aichatpb.CreateSessionRequest) (*aichatpb.ChatSession, error) {
	userID, err := c.getUserID(ctx)
	if err != nil {
		return nil, err
	}
	logger.D("ChatHandler: создание сессии \"%s\" пользователем %d", req.GetTitle(), userID)
	session, err := c.aiChatUseCase.CreateSession(ctx, userID, req.GetTitle(), req.GetModel())
	if err != nil {
		logger.E("ChatHandler: ошибка создания сессии: %v", err)
		return nil, error2.ToStatusError(codes.Internal, err)
	}
	logger.I("ChatHandler: сессия создана")

	return mappers.AIChatSessionToProto(session), nil
}

func (c *AIChatHandler) GetSession(ctx context.Context, req *aichatpb.GetSessionRequest) (*aichatpb.ChatSession, error) {
	userID, err := c.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	session, err := c.aiChatUseCase.GetSession(ctx, userID, req.SessionId)
	if err != nil {
		return nil, error2.ToStatusError(codes.NotFound, err)
	}

	return mappers.AIChatSessionToProto(session), nil
}

func (c *AIChatHandler) GetSessions(ctx context.Context, req *aichatpb.GetSessionsRequest) (*aichatpb.GetSessionsResponse, error) {
	userID, err := c.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	page, pageSize := pkg.NormalizePagination(req.Page, req.PageSize, 20)

	sessions, total, err := c.aiChatUseCase.GetSessions(ctx, userID, page, pageSize)
	if err != nil {
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	protoSessions := make([]*aichatpb.ChatSession, len(sessions))
	for i, session := range sessions {
		protoSessions[i] = mappers.AIChatSessionToProto(session)
	}

	return &aichatpb.GetSessionsResponse{
		Sessions: protoSessions,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

func (c *AIChatHandler) GetSessionMessages(ctx context.Context, req *aichatpb.GetSessionMessagesRequest) (*aichatpb.GetSessionMessagesResponse, error) {
	userID, err := c.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	page, pageSize := pkg.NormalizePagination(req.Page, req.PageSize, 50)

	messages, total, err := c.aiChatUseCase.GetSessionMessages(ctx, userID, req.SessionId, page, pageSize)
	if err != nil {
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	protoMessages := make([]*aichatpb.ChatMessage, len(messages))
	for i, msg := range messages {
		protoMessages[i] = mappers.AIMessageToProto(msg)
	}

	return &aichatpb.GetSessionMessagesResponse{
		Messages: protoMessages,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

func (c *AIChatHandler) DeleteSession(ctx context.Context, req *aichatpb.DeleteSessionRequest) (*commonpb.Empty, error) {
	userID, err := c.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	if err := c.aiChatUseCase.DeleteSession(ctx, userID, req.SessionId); err != nil {
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	return &commonpb.Empty{}, nil
}

func (c *AIChatHandler) UpdateSessionTitle(ctx context.Context, req *aichatpb.UpdateSessionTitleRequest) (*aichatpb.ChatSession, error) {
	userID, err := c.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	session, err := c.aiChatUseCase.UpdateSessionTitle(ctx, userID, req.SessionId, req.Title)
	if err != nil {
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	return mappers.AIChatSessionToProto(session), nil
}

func (c *AIChatHandler) UpdateSessionModel(ctx context.Context, req *aichatpb.UpdateSessionModelRequest) (*aichatpb.ChatSession, error) {
	userID, err := c.getUserID(ctx)
	if err != nil {
		return nil, err
	}

	session, err := c.aiChatUseCase.UpdateSessionModel(ctx, userID, req.SessionId, req.GetModel())
	if err != nil {
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	return mappers.AIChatSessionToProto(session), nil
}

func (c *AIChatHandler) CheckConnection(ctx context.Context, req *commonpb.Empty) (*aichatpb.ConnectionResponse, error) {
	return &aichatpb.ConnectionResponse{IsConnected: true}, nil
}

func (c *AIChatHandler) GetModels(ctx context.Context, req *commonpb.Empty) (*aichatpb.GetModelsResponse, error) {
	models, err := c.aiChatUseCase.GetModels(ctx)
	if err != nil {
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	return &aichatpb.GetModelsResponse{Models: models}, nil
}
