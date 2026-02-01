package usecase

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/pkg/logger"
)

type ChatUseCase struct {
	sessionRepo        domain.ChatSessionRepository
	messageRepo        domain.MessageRepository
	llmProvider        domain.LLMProvider
	attachmentsSaveDir string
}

func NewChatUseCase(
	sessionRepo domain.ChatSessionRepository,
	messageRepo domain.MessageRepository,
	llmProvider domain.LLMProvider,
	attachmentsSaveDir string,
) *ChatUseCase {
	return &ChatUseCase{
		sessionRepo:        sessionRepo,
		messageRepo:        messageRepo,
		llmProvider:        llmProvider,
		attachmentsSaveDir: attachmentsSaveDir,
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
	return c.llmProvider.GetModels(ctx)
}

func (c *ChatUseCase) SendMessage(ctx context.Context, userId int, sessionId string, model string, userMessage string, attachmentName string, attachmentContent []byte) (chan string, string, error) {
	logger.D("ChatUseCase: отправка сообщения в сессию %s", sessionId)
	_, err := c.verifySessionOwnership(ctx, userId, sessionId)
	if err != nil {
		logger.W("ChatUseCase: ошибка проверки сессии: %v", err)
		return nil, "", err
	}

	messages, _, err := c.messageRepo.GetBySessionId(ctx, sessionId, 1, 100)
	if err != nil {
		logger.E("ChatUseCase: ошибка получения сообщений: %v", err)
		return nil, "", err
	}

	userMsg := domain.NewMessageWithAttachment(sessionId, userMessage, domain.MessageRoleUser, attachmentName)
	if err := c.messageRepo.Create(ctx, userMsg); err != nil {
		return nil, "", err
	}

	if c.attachmentsSaveDir != "" && len(attachmentContent) > 0 && attachmentName != "" {
		_ = c.saveAttachment(sessionId, userMsg.Id, attachmentName, attachmentContent)
	}

	messagesForLLM := make([]*domain.Message, 0, len(messages)+1)
	messagesForLLM = append(messagesForLLM, messages...)
	if len(attachmentContent) > 0 && attachmentName != "" {
		fullContent := buildMessageWithFile(attachmentName, attachmentContent, userMessage)
		userMsgForLLM := *userMsg
		userMsgForLLM.Content = fullContent
		messagesForLLM = append(messagesForLLM, &userMsgForLLM)
	} else {
		messagesForLLM = append(messagesForLLM, userMsg)
	}

	responseChan, err := c.llmProvider.SendMessage(ctx, sessionId, model, messagesForLLM)
	if err != nil {
		logger.E("ChatUseCase: ошибка LLM: %v", err)
		return nil, "", err
	}
	logger.V("ChatUseCase: поток ответа запущен")

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

func buildMessageWithFile(attachmentName string, attachmentContent []byte, userMessage string) string {
	fileContent := string(attachmentContent)
	s := fmt.Sprintf("Файл «%s»:\n\n```\n%s\n```", attachmentName, fileContent)
	if userMessage != "" {
		s += "\n\n---\n\n" + userMessage
	}

	return s
}

func (c *ChatUseCase) saveAttachment(sessionId, messageId, attachmentName string, content []byte) error {
	baseName := filepath.Base(attachmentName)
	if baseName == "" || baseName == "." {
		baseName = "attachment"
	}
	dir := filepath.Join(c.attachmentsSaveDir, sessionId)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}
	name := messageId + "_" + baseName
	path := filepath.Join(dir, name)
	return os.WriteFile(path, content, 0644)
}
