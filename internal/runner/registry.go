package runner

import (
	"context"
	"github.com/magomedcoder/legion/api/pb/commonpb"

	"github.com/magomedcoder/legion/api/pb/runnerpb"
	"github.com/magomedcoder/legion/pkg/logger"
)

type Registry struct {
	runnerpb.UnimplementedRunnerServiceServer
	pool *Pool
}

func NewRegistry(pool *Pool) *Registry {
	return &Registry{
		pool: pool,
	}
}

func (r *Registry) Register(ctx context.Context, req *runnerpb.RegisterRunnerRequest) (*commonpb.Empty, error) {
	if req != nil && req.Address != "" {
		logger.I("Registry: регистрация раннера %s", req.Address)
		r.pool.Add(req.Address)
	}

	return &commonpb.Empty{}, nil
}

func (r *Registry) Unregister(ctx context.Context, req *runnerpb.UnregisterRunnerRequest) (*commonpb.Empty, error) {
	if req != nil && req.Address != "" {
		logger.I("Registry: снятие с регистрации раннера %s", req.Address)
		r.pool.Remove(req.Address)
	}

	return &commonpb.Empty{}, nil
}
