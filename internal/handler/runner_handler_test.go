package handler

import (
	"context"
	"testing"

	"github.com/magomedcoder/legion/api/pb/runnerpb"
	"github.com/magomedcoder/legion/internal/runner"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestRunnerHandler_GetRunners_noAuth(t *testing.T) {
	pool := runner.NewPool(nil)
	h := NewRunnerHandler(pool, nil)
	ctx := context.Background()

	_, err := h.GetRunners(ctx, &runnerpb.Empty{})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("GetRunners: код %v, ожидался Unauthenticated", code)
	}
}

func TestRunnerHandler_SetRunnerEnabled_noAuth(t *testing.T) {
	pool := runner.NewPool(nil)
	h := NewRunnerHandler(pool, nil)
	ctx := context.Background()

	_, err := h.SetRunnerEnabled(ctx, &runnerpb.SetRunnerEnabledRequest{
		Address: "a",
		Enabled: true,
	})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("SetRunnerEnabled: код %v, ожидался Unauthenticated", code)
	}
}

func TestRunnerHandler_GetRunnersStatus_noAuth(t *testing.T) {
	pool := runner.NewPool(nil)
	h := NewRunnerHandler(pool, nil)
	ctx := context.Background()

	_, err := h.GetRunnersStatus(ctx, &runnerpb.Empty{})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("GetRunnersStatus: код %v, ожидался Unauthenticated", code)
	}
}
