package handler

import (
	"context"

	"github.com/magomedcoder/legion/api/pb/commonpb"
	"github.com/magomedcoder/legion/api/pb/runnerpb"
	"github.com/magomedcoder/legion/internal/runner"
	"github.com/magomedcoder/legion/internal/usecase"
	"github.com/magomedcoder/legion/pkg/logger"
)

type RunnerHandler struct {
	runnerpb.UnimplementedRunnerAdminServiceServer
	pool        *runner.Pool
	authUseCase usecase.TokenValidator
}

func NewRunnerHandler(pool *runner.Pool, authUseCase usecase.TokenValidator) *RunnerHandler {
	return &RunnerHandler{
		pool:        pool,
		authUseCase: authUseCase,
	}
}

func (r *RunnerHandler) GetRunners(ctx context.Context, _ *commonpb.Empty) (*runnerpb.GetRunnersResponse, error) {
	logger.D("RunnerHandler: получение списка раннеров")
	items := r.pool.GetRunners()
	runners := make([]*runnerpb.RunnerInfo, len(items))
	for i := range items {
		ri := &runnerpb.RunnerInfo{
			Address:   items[i].Address,
			Enabled:   items[i].Enabled,
			Connected: items[i].Connected,
		}
		if items[i].Connected {
			if gpuResp := r.pool.GetGpuInfo(ctx, items[i].Address); gpuResp != nil && len(gpuResp.Gpus) > 0 {
				ri.Gpus = gpuResp.Gpus
			}
			if serverResp := r.pool.GetServerInfo(ctx, items[i].Address); serverResp != nil {
				ri.ServerInfo = serverResp
			}
		}
		runners[i] = ri
	}
	logger.V("RunnerHandler: раннеров: %d", len(runners))

	return &runnerpb.GetRunnersResponse{
		Runners: runners,
	}, nil
}

func (r *RunnerHandler) SetRunnerEnabled(ctx context.Context, req *runnerpb.SetRunnerEnabledRequest) (*commonpb.Empty, error) {
	if req != nil && req.Address != "" {
		logger.I("RunnerHandler: setRunnerEnabled %s enabled=%v", req.Address, req.Enabled)
		r.pool.SetRunnerEnabled(req.Address, req.Enabled)
	}

	return &commonpb.Empty{}, nil
}

func (r *RunnerHandler) GetRunnersStatus(ctx context.Context, _ *commonpb.Empty) (*runnerpb.GetRunnersStatusResponse, error) {
	return &runnerpb.GetRunnersStatusResponse{
		HasActiveRunners: r.pool.HasActiveRunners(),
	}, nil
}
