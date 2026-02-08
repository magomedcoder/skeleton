package handler

import (
	"context"
	"testing"

	"github.com/magomedcoder/legion/api/pb/editorpb"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/usecase"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

func TestEditorHandler_Transform_noAuth(t *testing.T) {
	h := NewEditorHandler(&usecase.EditorUseCase{}, nil)
	ctx := context.Background()

	_, err := h.Transform(ctx, &editorpb.TransformRequest{
		Text: "привет",
	})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("Transform: код %v, ожидался Unauthenticated", code)
	}
}

func TestEditorHandler_Transform_emptyText_returnsInvalidArgument(t *testing.T) {
	auth := &fakeAuth{
		user: &domain.User{
			Id:       1,
			Username: "u",
			Role:     domain.UserRoleUser,
		},
	}
	h := NewEditorHandler(&usecase.EditorUseCase{}, auth)
	ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "Bearer tok"))

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
	auth := &fakeAuth{
		user: &domain.User{
			Id: 1,
		},
	}
	h := NewEditorHandler(&usecase.EditorUseCase{}, auth)
	ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "Bearer tok"))

	_, err := h.Transform(ctx, nil)
	if err == nil {
		t.Fatal("ожидалась ошибка для nil-запроса")
	}

	if code := status.Code(err); code != codes.InvalidArgument {
		t.Errorf("Transform(nil): код %v, ожидался InvalidArgument", code)
	}
}
