package handler

import (
	"context"
	"github.com/magomedcoder/legion/api/pb/commonpb"
	"testing"

	"github.com/magomedcoder/legion/api/pb/runnerpb"
	"github.com/magomedcoder/legion/internal/runner"
)

func TestRunnerHandler_GetRunners_returnsEmptyList(t *testing.T) {
	pool := runner.NewPool(nil)
	h := NewRunnerHandler(pool, nil)
	ctx := context.Background()

	resp, err := h.GetRunners(ctx, &commonpb.Empty{})
	if err != nil {
		t.Fatalf("GetRunners: %v", err)
	}
	if resp == nil || len(resp.Runners) != 0 {
		t.Errorf("GetRunners: ожидался пустой список, получено %v", resp)
	}
}

func TestRunnerHandler_GetRunnersStatus_returnsResponse(t *testing.T) {
	pool := runner.NewPool(nil)
	h := NewRunnerHandler(pool, nil)
	ctx := context.Background()

	resp, err := h.GetRunnersStatus(ctx, &commonpb.Empty{})
	if err != nil {
		t.Fatalf("GetRunnersStatus: %v", err)
	}

	if resp == nil {
		t.Fatal("GetRunnersStatus: ответ nil")
	}

	if resp.HasActiveRunners {
		t.Errorf("GetRunnersStatus: ожидалось HasActiveRunners=false")
	}
}

func TestRunnerHandler_SetRunnerEnabled_emptyAddress_noError(t *testing.T) {
	pool := runner.NewPool(nil)
	h := NewRunnerHandler(pool, nil)
	ctx := context.Background()

	_, err := h.SetRunnerEnabled(ctx, &runnerpb.SetRunnerEnabledRequest{
		Address: "",
		Enabled: true,
	})
	if err != nil {
		t.Errorf("SetRunnerEnabled(пустой address): %v", err)
	}

	_, err = h.SetRunnerEnabled(ctx, &runnerpb.SetRunnerEnabledRequest{
		Address: "localhost:8080",
		Enabled: true,
	})
	if err != nil {
		t.Errorf("SetRunnerEnabled: %v", err)
	}
}
