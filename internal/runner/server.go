package runner

import (
	"context"
	"github.com/magomedcoder/skeleton/api/pb/runnerpb"
	"github.com/magomedcoder/skeleton/internal/mappers"
	"github.com/magomedcoder/skeleton/internal/runner/gpu"
	"github.com/magomedcoder/skeleton/internal/runner/provider"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type Server struct {
	runnerpb.UnimplementedRunnerServiceServer
	textProvider provider.TextProvider
	gpuCollector gpu.Collector
}

func NewServer(textProvider provider.TextProvider, gpuCollector gpu.Collector) *Server {
	if gpuCollector == nil {
		gpuCollector = gpu.NewCollector()
	}
	return &Server{
		textProvider: textProvider,
		gpuCollector: gpuCollector,
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

func (s *Server) GetGpuInfo(ctx context.Context, _ *runnerpb.Empty) (*runnerpb.GetGpuInfoResponse, error) {
	list := s.gpuCollector.Collect()
	gpus := make([]*runnerpb.GpuInfo, len(list))
	for i := range list {
		gpus[i] = &runnerpb.GpuInfo{
			Name:               list[i].Name,
			TemperatureC:       list[i].TemperatureC,
			MemoryTotalMb:      list[i].MemoryTotalMB,
			MemoryUsedMb:       list[i].MemoryUsedMB,
			UtilizationPercent: list[i].UtilizationPercent,
		}
	}
	return &runnerpb.GetGpuInfoResponse{Gpus: gpus}, nil
}

func (s *Server) GetServerInfo(ctx context.Context, _ *runnerpb.Empty) (*runnerpb.ServerInfo, error) {
	si := CollectSysInfo()
	out := &runnerpb.ServerInfo{
		Hostname:      si.Hostname,
		Os:            si.OS,
		Arch:          si.Arch,
		CpuCores:      si.CPUCores,
		MemoryTotalMb: si.MemoryTotalMB,
	}
	if s.textProvider != nil {
		if models, err := s.textProvider.GetModels(ctx); err == nil && len(models) > 0 {
			out.Models = models
		}
	}
	return out, nil
}
