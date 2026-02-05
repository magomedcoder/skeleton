package handler

import (
	"context"

	"github.com/magomedcoder/skeleton/api/pb/editorpb"
	"github.com/magomedcoder/skeleton/internal/usecase"
	"github.com/magomedcoder/skeleton/pkg/logger"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type EditorHandler struct {
	editorpb.UnimplementedEditorServiceServer
	editorUseCase *usecase.EditorUseCase
	authUseCase   *usecase.AuthUseCase
}

func NewEditorHandler(editorUseCase *usecase.EditorUseCase, authUseCase *usecase.AuthUseCase) *EditorHandler {
	return &EditorHandler{
		editorUseCase: editorUseCase,
		authUseCase:   authUseCase,
	}
}

func (e *EditorHandler) Transform(ctx context.Context, req *editorpb.TransformRequest) (*editorpb.TransformResponse, error) {
	_, err := GetUserFromContext(ctx, e.authUseCase)
	if err != nil {
		return nil, err
	}

	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "пустой запрос")
	}

	if req.Text == "" {
		return nil, status.Error(codes.InvalidArgument, "текст не предоставлен")
	}

	logger.D("EditorHandler: transform model=%q", req.Model)

	out, err := e.editorUseCase.Transform(ctx, req.GetModel(), req.GetText())
	if err != nil {
		return nil, ToStatusError(codes.Internal, err)
	}

	return &editorpb.TransformResponse{Text: out}, nil
}
