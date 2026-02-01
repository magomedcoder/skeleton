package runner

import (
	"context"
	"github.com/magomedcoder/legion/api/pb/runnerpb"
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

func (r *Registry) Register(ctx context.Context, req *runnerpb.RegisterRunnerRequest) (*runnerpb.Empty, error) {
	if req != nil && req.Address != "" {
		r.pool.Add(req.Address)
	}

	return &runnerpb.Empty{}, nil
}

func (r *Registry) Unregister(ctx context.Context, req *runnerpb.UnregisterRunnerRequest) (*runnerpb.Empty, error) {
	if req != nil && req.Address != "" {
		r.pool.Remove(req.Address)
	}

	return &runnerpb.Empty{}, nil
}
