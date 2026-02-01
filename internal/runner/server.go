package runner

import (
	"context"

	"github.com/magomedcoder/legion/api/pb/runnerpb"
	"github.com/magomedcoder/legion/internal/mappers"
	"github.com/magomedcoder/legion/internal/runner/provider"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type Server struct {
	runnerpb.UnimplementedRunnerServiceServer
	textProvider provider.TextProvider
}

func NewServer(textProvider provider.TextProvider) *Server {
	return &Server{
		textProvider: textProvider,
	}
}

func (s *Server) Ping(ctx context.Context, _ *runnerpb.Empty) (*runnerpb.PingResponse, error) {
	if s.textProvider == nil {
		return &runnerpb.PingResponse{
			Ok: false,
		}, nil
	}

	ok, _ := s.textProvider.CheckConnection(ctx)
	return &runnerpb.PingResponse{
		Ok: ok,
	}, nil
}

func (s *Server) GetModels(ctx context.Context, _ *runnerpb.Empty) (*runnerpb.GetModelsResponse, error) {
	if s.textProvider == nil {
		return &runnerpb.GetModelsResponse{}, nil
	}

	models, err := s.textProvider.GetModels(ctx)
	if err != nil {
		return &runnerpb.GetModelsResponse{}, nil
	}

	return &runnerpb.GetModelsResponse{
		Models: models,
	}, nil
}

func (s *Server) Generate(req *runnerpb.GenerateRequest, stream runnerpb.RunnerService_GenerateServer) error {
	if s.textProvider == nil {
		return status.Error(codes.Unavailable, "текстовый провайдер не подключён")
	}

	if req == nil || len(req.Messages) == 0 {
		return stream.Send(&runnerpb.GenerateResponse{
			Done: true,
		})
	}

	sessionID := req.SessionId
	model := req.Model
	messages := mappers.MessagesFromProto(req.Messages, sessionID)

	ctx := stream.Context()
	ch, err := s.textProvider.SendMessage(ctx, sessionID, model, messages)
	if err != nil {
		_ = stream.Send(&runnerpb.GenerateResponse{
			Done: true,
		})
		return err
	}

	for chunk := range ch {
		if chunk != "" {
			if err := stream.Send(&runnerpb.GenerateResponse{
				Content: chunk,
				Done:    false,
			}); err != nil {
				return err
			}
		}
	}

	return stream.Send(&runnerpb.GenerateResponse{
		Done: true,
	})
}
