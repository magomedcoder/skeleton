package handler

import (
	"context"
	"testing"

	"github.com/magomedcoder/legion/api/pb/editorpb"
	"github.com/magomedcoder/legion/internal/usecase"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestEditorHandler_Transform_emptyText_returnsInvalidArgument(t *testing.T) {
	h := NewEditorHandler(&usecase.EditorUseCase{}, nil)
	ctx := context.Background()

	_, err := h.Transform(ctx, &editorpb.TransformRequest{
		Text: "",
	})
	if err == nil {
		t.Fatal("ожидалась ошибка для пустого текста")
	}
	if code := status.Code(err); code != codes.InvalidArgument {
		t.Errorf("Transform(пустой текст): код %v, ожидался InvalidArgument", code)
	}
}

func TestEditorHandler_Transform_nilRequest_returnsInvalidArgument(t *testing.T) {
	h := NewEditorHandler(&usecase.EditorUseCase{}, nil)
	ctx := context.Background()

	_, err := h.Transform(ctx, nil)
	if err == nil {
		t.Fatal("ожидалась ошибка для nil-запроса")
	}
	if code := status.Code(err); code != codes.InvalidArgument {
		t.Errorf("Transform(nil): код %v, ожидался InvalidArgument", code)
	}
}
