package handler

import (
	"context"
	"github.com/magomedcoder/legion/internal/runner"

	"github.com/magomedcoder/legion/api/pb/runnerpb"
	"github.com/magomedcoder/legion/internal/usecase"
)

type RunnerHandler struct {
	runnerpb.UnimplementedRunnerAdminServiceServer
	pool        *runner.Pool
	authUseCase *usecase.AuthUseCase
}

func NewRunnerHandler(pool *runner.Pool, authUseCase *usecase.AuthUseCase) *RunnerHandler {
	return &RunnerHandler{
		pool:        pool,
		authUseCase: authUseCase,
	}
}

func (r *RunnerHandler) GetRunners(ctx context.Context, _ *runnerpb.Empty) (*runnerpb.GetRunnersResponse, error) {
	if err := RequireAdmin(ctx, r.authUseCase); err != nil {
		return nil, err
	}
	items := r.pool.GetRunners()
	runners := make([]*runnerpb.RunnerInfo, len(items))
	for i := range items {
		runners[i] = &runnerpb.RunnerInfo{
			Address: items[i].Address,
			Enabled: items[i].Enabled,
		}
	}

	return &runnerpb.GetRunnersResponse{
		Runners: runners,
	}, nil
}

func (r *RunnerHandler) SetRunnerEnabled(ctx context.Context, req *runnerpb.SetRunnerEnabledRequest) (*runnerpb.Empty, error) {
	if err := RequireAdmin(ctx, r.authUseCase); err != nil {
		return nil, err
	}
	if req != nil && req.Address != "" {
		r.pool.SetRunnerEnabled(req.Address, req.Enabled)
	}

	return &runnerpb.Empty{}, nil
}

func (r *RunnerHandler) GetRunnersStatus(ctx context.Context, _ *runnerpb.Empty) (*runnerpb.GetRunnersStatusResponse, error) {
	if _, err := GetUserFromContext(ctx, r.authUseCase); err != nil {
		return nil, err
	}

	return &runnerpb.GetRunnersStatusResponse{
		HasActiveRunners: r.pool.HasActiveRunners(),
	}, nil
}
