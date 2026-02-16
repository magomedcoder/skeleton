package runner

import (
	"context"
	"crypto/subtle"
	"strings"

	"github.com/magomedcoder/legion/api/pb/commonpb"
	"github.com/magomedcoder/legion/api/pb/runnerpb"
	"github.com/magomedcoder/legion/pkg/logger"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

const MetadataRunnerToken = "x-runner-token"

type Registry struct {
	runnerpb.UnimplementedRunnerServiceServer
	pool     *Pool
	regToken string
}

func NewRegistry(pool *Pool, registrationToken string) *Registry {
	return &Registry{
		pool:     pool,
		regToken: strings.TrimSpace(registrationToken),
	}
}

func (r *Registry) validateRunnerToken(ctx context.Context) error {
	if r.regToken == "" {
		return nil
	}
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return status.Error(codes.Unauthenticated, "метаданные не предоставлены")
	}

	vals := md.Get(MetadataRunnerToken)
	if len(vals) == 0 || vals[0] == "" {
		return status.Error(codes.Unauthenticated, "токен регистрации раннера не предоставлен")
	}

	if subtle.ConstantTimeCompare([]byte(vals[0]), []byte(r.regToken)) != 1 {
		return status.Error(codes.Unauthenticated, "неверный токен регистрации раннера")
	}

	return nil
}

func (r *Registry) Register(ctx context.Context, req *runnerpb.RegisterRunnerRequest) (*commonpb.Empty, error) {
	if err := r.validateRunnerToken(ctx); err != nil {
		return nil, err
	}

	if req != nil && req.Address != "" {
		logger.I("Registry: регистрация раннера %s", req.Address)
		r.pool.Add(req.Address)
	}

	return &commonpb.Empty{}, nil
}

func (r *Registry) Unregister(ctx context.Context, req *runnerpb.UnregisterRunnerRequest) (*commonpb.Empty, error) {
	if err := r.validateRunnerToken(ctx); err != nil {
		return nil, err
	}

	if req != nil && req.Address != "" {
		logger.I("Registry: снятие с регистрации раннера %s", req.Address)
		r.pool.Remove(req.Address)
	}

	return &commonpb.Empty{}, nil
}
