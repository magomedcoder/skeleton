package usecase

import (
	"context"
	"strings"

	"github.com/magomedcoder/legion/internal/domain"
)

type ChatUseCase struct {
	sessionRepo domain.ChatSessionRepository
	messageRepo domain.MessageRepository
	ollamaRepo  domain.OllamaRepository
}

func NewChatUseCase(
	sessionRepo domain.ChatSessionRepository,
	messageRepo domain.MessageRepository,
	ollamaRepo domain.OllamaRepository,
) *ChatUseCase {
	return &ChatUseCase{
		sessionRepo: sessionRepo,
		messageRepo: messageRepo,
		ollamaRepo:  ollamaRepo,
	}
}

func (uc *ChatUseCase) verifySessionOwnership(ctx context.Context, userId int, sessionID string) (*domain.ChatSession, error) {
	session, err := uc.sessionRepo.GetById(ctx, sessionID)
	if err != nil {
		return nil, err
	}
	if session.UserId != userId {
		return nil, domain.ErrUnauthorized
	}
	return session, nil
}

func (uc *ChatUseCase) SendMessage(ctx context.Context, userId int, sessionId string, userMessage string) (chan string, string, error) {
	_, err := uc.verifySessionOwnership(ctx, userId, sessionId)
	if err != nil {
		return nil, "", err
	}

	userMsg := domain.NewMessage(sessionId, userMessage, domain.MessageRoleUser)
	if err := uc.messageRepo.Create(ctx, userMsg); err != nil {
		return nil, "", err
	}

	messages, _, err := uc.messageRepo.GetBySessionId(ctx, sessionId, 1, 100)
	if err != nil {
		return nil, "", err
	}

	responseChan, err := uc.ollamaRepo.SendMessage(ctx, sessionId, messages)
	if err != nil {
		return nil, "", err
	}

	assistantMsg := domain.NewMessage(sessionId, "", domain.MessageRoleAssistant)
	messageId := assistantMsg.Id
	var fullResponse strings.Builder

	clientChan := make(chan string, 100)
	go func() {
		defer func() {
			assistantMsg.Content = fullResponse.String()
			uc.messageRepo.Create(context.Background(), assistantMsg)
		}()
		defer close(clientChan)

		for chunk := range responseChan {
			fullResponse.WriteString(chunk)
			select {
			case <-ctx.Done():
				return
			case clientChan <- chunk:
			}
		}
	}()

	return clientChan, messageId, nil
}

func (uc *ChatUseCase) CreateSession(ctx context.Context, userId int, title string) (*domain.ChatSession, error) {
	session := domain.NewChatSession(userId, title)
	if err := uc.sessionRepo.Create(ctx, session); err != nil {
		return nil, err
	}

	return session, nil
}

func (uc *ChatUseCase) GetSession(ctx context.Context, userId int, sessionID string) (*domain.ChatSession, error) {
	return uc.verifySessionOwnership(ctx, userId, sessionID)
}

func (uc *ChatUseCase) GetSessions(ctx context.Context, userId int, page, pageSize int32) ([]*domain.ChatSession, int32, error) {
	return uc.sessionRepo.GetByUserId(ctx, userId, page, pageSize)
}

func (uc *ChatUseCase) GetSessionMessages(ctx context.Context, userId int, sessionId string, page, pageSize int32) ([]*domain.Message, int32, error) {
	_, err := uc.verifySessionOwnership(ctx, userId, sessionId)
	if err != nil {
		return nil, 0, err
	}

	return uc.messageRepo.GetBySessionId(ctx, sessionId, page, pageSize)
}

func (uc *ChatUseCase) DeleteSession(ctx context.Context, userId int, sessionID string) error {
	_, err := uc.verifySessionOwnership(ctx, userId, sessionID)
	if err != nil {
		return err
	}

	return uc.sessionRepo.Delete(ctx, sessionID)
}

func (uc *ChatUseCase) UpdateSessionTitle(ctx context.Context, userId int, sessionId string, title string) (*domain.ChatSession, error) {
	session, err := uc.verifySessionOwnership(ctx, userId, sessionId)
	if err != nil {
		return nil, err
	}

	session.Title = title
	if err := uc.sessionRepo.Update(ctx, session); err != nil {
		return nil, err
	}

	return session, nil
}
