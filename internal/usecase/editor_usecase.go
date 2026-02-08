package usecase

import (
	"context"
	"fmt"
	"github.com/magomedcoder/skeleton/api/pb/editorpb"
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

func (e *EditorUseCase) Transform(ctx context.Context, model string, text string, t editorpb.TransformType, preserveMarkdown bool) (string, error) {
	if strings.TrimSpace(text) == "" {
		return "", fmt.Errorf("пустой текст")
	}

	sessionId := uuid.New().String()
	system := buildEditorSystemPrompt(t, preserveMarkdown)

	messages := []*domain.AIChatMessage{
		domain.NewAIChatMessage(sessionId, system, domain.AIChatMessageRoleSystem),
		domain.NewAIChatMessage(sessionId, wrapUserText(text), domain.AIChatMessageRoleUser),
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

func buildEditorSystemPrompt(t editorpb.TransformType, preserveMarkdown bool) string {
	action := "улучши текст"
	switch t {
	case editorpb.TransformType_TRANSFORM_TYPE_FIX:
		action = "исправь орфографию, пунктуацию и грамматику"
	case editorpb.TransformType_TRANSFORM_TYPE_IMPROVE:
		action = "улучши текст: сделай яснее, логичнее и читабельнее, не меняя смысл"
	case editorpb.TransformType_TRANSFORM_TYPE_BEAUTIFY:
		action = "сделай текст более красивым и выразительным, сохраняя смысл"
	case editorpb.TransformType_TRANSFORM_TYPE_PARAPHRASE:
		action = "перефразируй (другими словами), сохраняя смысл"
	case editorpb.TransformType_TRANSFORM_TYPE_SHORTEN:
		action = "сократи текст, сохранив ключевой смысл и факты"
	case editorpb.TransformType_TRANSFORM_TYPE_SIMPLIFY:
		action = "упрости текст: сделай проще и понятнее, без потери смысла"
	case editorpb.TransformType_TRANSFORM_TYPE_MAKE_COMPLEX:
		action = "сделай текст более сложным/профессиональным: добавь точности и терминов, сохраняя смысл"
	case editorpb.TransformType_TRANSFORM_TYPE_MORE_FORMAL:
		action = "перепиши в более формальном стиле"
	case editorpb.TransformType_TRANSFORM_TYPE_MORE_CASUAL:
		action = "перепиши в разговорном стиле"
	default:
		action = "улучши текст"
	}

	formatRule := "Сохраняй переносы строк и структуру по смыслу."
	if preserveMarkdown {
		formatRule = "Сохраняй Markdown/разметку, списки и переносы строк (если они есть)."
	}

	return fmt.Sprintf(
		"Ты — редактор текста. Задача: %s.\n"+
			"Правила:\n"+
			"- Верни ТОЛЬКО итоговый отредактированный текст, без пояснений.\n"+
			"- Сохраняй смысл; не добавляй новых фактов.\n"+
			"- Имена, числа, даты и сущности не меняй (кроме явных опечаток).\n"+
			"- %s\n",
		action, formatRule,
	)
}
