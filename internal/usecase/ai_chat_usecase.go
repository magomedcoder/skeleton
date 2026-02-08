package usecase

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/pkg/document"
	"github.com/magomedcoder/legion/pkg/logger"
)

type AIChatUseCase struct {
	aiChatRepo         domain.AIChatRepository
	aiChatMessageRepo  domain.AIChatMessageRepository
	fileRepo           domain.FileRepository
	llmProvider        domain.LLMProvider
	attachmentsSaveDir string
}

func NewAIChatUseCase(
	aiChatRepo domain.AIChatRepository,
	aiChatMessageRepo domain.AIChatMessageRepository,
	fileRepo domain.FileRepository,
	llmProvider domain.LLMProvider,
	attachmentsSaveDir string,
) *AIChatUseCase {
	return &AIChatUseCase{
		aiChatRepo:         aiChatRepo,
		aiChatMessageRepo:  aiChatMessageRepo,
		fileRepo:           fileRepo,
		llmProvider:        llmProvider,
		attachmentsSaveDir: attachmentsSaveDir,
	}
}

func (ai *AIChatUseCase) verifySessionOwnership(ctx context.Context, userId int, sessionID string) (*domain.AIChatSession, error) {
	session, err := ai.aiChatRepo.GetById(ctx, sessionID)
	if err != nil {
		return nil, err
	}
	if session.UserId != userId {
		return nil, domain.ErrUnauthorized
	}
	return session, nil
}

func (ai *AIChatUseCase) GetModels(ctx context.Context) ([]string, error) {
	return ai.llmProvider.GetModels(ctx)
}

func (ai *AIChatUseCase) SendMessage(ctx context.Context, userId int, sessionId string, model string, userMessage string, attachmentName string, attachmentContent []byte) (chan string, string, error) {
	logger.D("ChatUseCase: отправка сообщения в сессию %s", sessionId)
	_, err := ai.verifySessionOwnership(ctx, userId, sessionId)
	if err != nil {
		logger.W("ChatUseCase: ошибка проверки сессии: %v", err)
		return nil, "", err
	}

	messages, _, err := ai.aiChatMessageRepo.GetBySessionId(ctx, sessionId, 1, 100)
	if err != nil {
		logger.E("ChatUseCase: ошибка получения сообщений: %v", err)
		return nil, "", err
	}

	var attachmentFileID string
	if len(attachmentContent) > 0 && attachmentName != "" && ai.attachmentsSaveDir != "" {
		file, _, err := ai.saveAttachmentAndCreateFile(ctx, sessionId, attachmentName, attachmentContent)
		if err == nil {
			attachmentFileID = file.Id
			if err := ai.fileRepo.Create(ctx, file); err != nil {
				logger.W("ChatUseCase: не удалось сохранить запись файла: %v", err)
				attachmentFileID = ""
			}
		}
	}

	userMsg := domain.NewAIChatMessageWithAttachment(sessionId, userMessage, domain.AIChatMessageRoleUser, attachmentFileID)
	if err := ai.aiChatMessageRepo.Create(ctx, userMsg); err != nil {
		return nil, "", err
	}

	messagesForLLM := make([]*domain.AIChatMessage, 0, len(messages)+1)
	messagesForLLM = append(messagesForLLM, messages...)
	if len(attachmentContent) > 0 && attachmentName != "" {
		fullContent := buildMessageWithFile(attachmentName, attachmentContent, userMessage)
		userMsgForLLM := *userMsg
		userMsgForLLM.Content = fullContent
		messagesForLLM = append(messagesForLLM, &userMsgForLLM)
	} else {
		messagesForLLM = append(messagesForLLM, userMsg)
	}

	responseChan, err := ai.llmProvider.SendMessage(ctx, sessionId, model, messagesForLLM)
	if err != nil {
		logger.E("ChatUseCase: ошибка LLM: %v", err)
		return nil, "", err
	}
	logger.V("ChatUseCase: поток ответа запущен")

	assistantMsg := domain.NewAIChatMessage(sessionId, "", domain.AIChatMessageRoleAssistant)
	messageId := assistantMsg.Id
	var fullResponse strings.Builder

	clientChan := make(chan string, 100)
	go func() {
		defer func() {
			assistantMsg.Content = fullResponse.String()
			ai.aiChatMessageRepo.Create(context.Background(), assistantMsg)
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

func (ai *AIChatUseCase) CreateSession(ctx context.Context, userId int, title string, model string) (*domain.AIChatSession, error) {
	session := domain.NewAIChatSession(userId, title, model)
	if err := ai.aiChatRepo.Create(ctx, session); err != nil {
		return nil, err
	}

	return session, nil
}

func (ai *AIChatUseCase) GetSession(ctx context.Context, userId int, sessionID string) (*domain.AIChatSession, error) {
	return ai.verifySessionOwnership(ctx, userId, sessionID)
}

func (ai *AIChatUseCase) GetSessions(ctx context.Context, userId int, page, pageSize int32) ([]*domain.AIChatSession, int32, error) {
	return ai.aiChatRepo.GetByUserId(ctx, userId, page, pageSize)
}

func (ai *AIChatUseCase) GetSessionMessages(ctx context.Context, userId int, sessionId string, page, pageSize int32) ([]*domain.AIChatMessage, int32, error) {
	_, err := ai.verifySessionOwnership(ctx, userId, sessionId)
	if err != nil {
		return nil, 0, err
	}

	return ai.aiChatMessageRepo.GetBySessionId(ctx, sessionId, page, pageSize)
}

func (ai *AIChatUseCase) DeleteSession(ctx context.Context, userId int, sessionID string) error {
	_, err := ai.verifySessionOwnership(ctx, userId, sessionID)
	if err != nil {
		return err
	}

	return ai.aiChatRepo.Delete(ctx, sessionID)
}

func (ai *AIChatUseCase) UpdateSessionTitle(ctx context.Context, userId int, sessionId string, title string) (*domain.AIChatSession, error) {
	session, err := ai.verifySessionOwnership(ctx, userId, sessionId)
	if err != nil {
		return nil, err
	}

	session.Title = title
	if err := ai.aiChatRepo.Update(ctx, session); err != nil {
		return nil, err
	}

	return session, nil
}

func (ai *AIChatUseCase) UpdateSessionModel(ctx context.Context, userId int, sessionId string, model string) (*domain.AIChatSession, error) {
	session, err := ai.verifySessionOwnership(ctx, userId, sessionId)
	if err != nil {
		return nil, err
	}

	session.Model = model
	if err := ai.aiChatRepo.Update(ctx, session); err != nil {
		return nil, err
	}

	return session, nil
}

func buildMessageWithFile(attachmentName string, attachmentContent []byte, userMessage string) string {
	fileContent, err := document.ExtractText(attachmentName, attachmentContent)
	if err != nil {
		logger.W("ChatUseCase: извлечение текста из вложения %q: %v, используем сырое содержимое", attachmentName, err)
		fileContent = string(attachmentContent)
	}
	s := fmt.Sprintf("Файл «%s»:\n\n```\n%s\n```", attachmentName, fileContent)
	if userMessage != "" {
		s += "\n\n---\n\n" + userMessage
	}

	return s
}

func (ai *AIChatUseCase) saveAttachmentAndCreateFile(ctx context.Context, sessionId, attachmentName string, content []byte) (*domain.File, string, error) {
	baseName := filepath.Base(attachmentName)
	if baseName == "" || baseName == "." {
		baseName = "attachment"
	}

	dir := filepath.Join(ai.attachmentsSaveDir, sessionId)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, "", err
	}

	file := domain.NewFile(baseName, "", int64(len(content)), "")
	storageName := file.Id + "_" + baseName
	storagePath := filepath.Join(dir, storageName)
	file.StoragePath = storagePath
	if err := os.WriteFile(storagePath, content, 0644); err != nil {
		return nil, "", err
	}

	return file, storagePath, nil
}
