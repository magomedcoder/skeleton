package usecase

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/magomedcoder/skeleton/internal/domain"
)

type EditorUseCase struct {
	llmProvider domain.LLMProvider
}

func NewEditorUseCase(llmProvider domain.LLMProvider) *EditorUseCase {
	return &EditorUseCase{
		llmProvider: llmProvider,
	}
}

func (e *EditorUseCase) Transform(ctx context.Context, model string, text string) (string, error) {
	if strings.TrimSpace(text) == "" {
		return "", fmt.Errorf("пустой текст")
	}

	sessionId := uuid.New().String()
	system := "Ты - редактор текста. Задача: исправь орфографию, пунктуацию и грамматику.\n" +
		"Правила:\n" +
		"- Верни ТОЛЬКО итоговый отредактированный текст, без пояснений.\n" +
		"- Сохраняй смысл; не добавляй новых фактов.\n" +
		"- Имена, числа, даты и сущности не меняй (кроме явных опечаток).\n" +
		"- Сохраняй переносы строк и структуру по смыслу.\n"

	messages := []*domain.Message{
		domain.NewMessage(sessionId, system, domain.MessageRoleSystem),
		domain.NewMessage(sessionId, wrapUserText(text), domain.MessageRoleUser),
	}

	ch, err := e.llmProvider.SendMessage(ctx, sessionId, model, messages)
	if err != nil {
		return "", err
	}

	var b strings.Builder
	for chunk := range ch {
		b.WriteString(chunk)
	}

	return strings.TrimSpace(b.String()), nil
}

func wrapUserText(text string) string {
	return "Текст:\n\n```\n" + text + "\n```"
}
