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

func (c *ChatUseCase) verifySessionOwnership(ctx context.Context, userId int, sessionID string) (*domain.ChatSession, error) {
	session, err := c.sessionRepo.GetById(ctx, sessionID)
	if err != nil {
		return nil, err
	}
	if session.UserId != userId {
		return nil, domain.ErrUnauthorized
	}
	return session, nil
}

func (c *ChatUseCase) GetModels(ctx context.Context) ([]string, error) {
	return c.ollamaRepo.GetModels(ctx)
}

func (c *ChatUseCase) SendMessage(ctx context.Context, userId int, sessionId string, model string, userMessage string) (chan string, string, error) {
	_, err := c.verifySessionOwnership(ctx, userId, sessionId)
	if err != nil {
		return nil, "", err
	}

	userMsg := domain.NewMessage(sessionId, userMessage, domain.MessageRoleUser)
	if err := c.messageRepo.Create(ctx, userMsg); err != nil {
		return nil, "", err
	}

	messages, _, err := c.messageRepo.GetBySessionId(ctx, sessionId, 1, 100)
	if err != nil {
		return nil, "", err
	}

	responseChan, err := c.ollamaRepo.SendMessage(ctx, sessionId, model, messages)
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
			c.messageRepo.Create(context.Background(), assistantMsg)
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

func (c *ChatUseCase) CreateSession(ctx context.Context, userId int, title string, model string) (*domain.ChatSession, error) {
	session := domain.NewChatSession(userId, title, model)
	if err := c.sessionRepo.Create(ctx, session); err != nil {
		return nil, err
	}

	return session, nil
}

func (c *ChatUseCase) GetSession(ctx context.Context, userId int, sessionID string) (*domain.ChatSession, error) {
	return c.verifySessionOwnership(ctx, userId, sessionID)
}

func (c *ChatUseCase) GetSessions(ctx context.Context, userId int, page, pageSize int32) ([]*domain.ChatSession, int32, error) {
	return c.sessionRepo.GetByUserId(ctx, userId, page, pageSize)
}

func (c *ChatUseCase) GetSessionMessages(ctx context.Context, userId int, sessionId string, page, pageSize int32) ([]*domain.Message, int32, error) {
	_, err := c.verifySessionOwnership(ctx, userId, sessionId)
	if err != nil {
		return nil, 0, err
	}

	return c.messageRepo.GetBySessionId(ctx, sessionId, page, pageSize)
}

func (c *ChatUseCase) DeleteSession(ctx context.Context, userId int, sessionID string) error {
	_, err := c.verifySessionOwnership(ctx, userId, sessionID)
	if err != nil {
		return err
	}

	return c.sessionRepo.Delete(ctx, sessionID)
}

func (c *ChatUseCase) UpdateSessionTitle(ctx context.Context, userId int, sessionId string, title string) (*domain.ChatSession, error) {
	session, err := c.verifySessionOwnership(ctx, userId, sessionId)
	if err != nil {
		return nil, err
	}

	session.Title = title
	if err := c.sessionRepo.Update(ctx, session); err != nil {
		return nil, err
	}

	return session, nil
}

func (c *ChatUseCase) UpdateSessionModel(ctx context.Context, userId int, sessionId string, model string) (*domain.ChatSession, error) {
	session, err := c.verifySessionOwnership(ctx, userId, sessionId)
	if err != nil {
		return nil, err
	}

	session.Model = model
	if err := c.sessionRepo.Update(ctx, session); err != nil {
		return nil, err
	}

	return session, nil
}
