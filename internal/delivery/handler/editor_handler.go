package handler

import (
	"context"

	"github.com/magomedcoder/legion/api/pb/editorpb"
	"github.com/magomedcoder/legion/internal/usecase"
	error2 "github.com/magomedcoder/legion/pkg/error"
	"github.com/magomedcoder/legion/pkg/logger"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type EditorHandler struct {
	editorpb.UnimplementedEditorServiceServer
	editorUseCase *usecase.EditorUseCase
	authUseCase   usecase.TokenValidator
}

func NewEditorHandler(editorUseCase *usecase.EditorUseCase, authUseCase usecase.TokenValidator) *EditorHandler {
	return &EditorHandler{
		editorUseCase: editorUseCase,
		authUseCase:   authUseCase,
	}
}

func (e *EditorHandler) Transform(ctx context.Context, req *editorpb.TransformRequest) (*editorpb.TransformResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "пустой запрос")
	}

	if req.Text == "" {
		return nil, status.Error(codes.InvalidArgument, "текст не предоставлен")
	}

	logger.D("EditorHandler: transform type=%v model=%q", req.Type, req.Model)

	out, err := e.editorUseCase.Transform(ctx, req.GetModel(), req.GetText(), req.GetType(), req.GetPreserveMarkdown())
	if err != nil {
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	return &editorpb.TransformResponse{Text: out}, nil
}
