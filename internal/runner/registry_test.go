package runner

import (
	"context"
	"testing"

	"github.com/magomedcoder/skeleton/api/pb/runnerpb"
)

func TestNewRegistry(t *testing.T) {
	pool := NewPool(nil)
	r := NewRegistry(pool)
	if r == nil {
		t.Fatal("NewRegistry не должен возвращать nil")
	}
}

func TestRegistry_Register_Unregister(t *testing.T) {
	pool := NewPool(nil)
	r := NewRegistry(pool)
	ctx := context.Background()

	_, err := r.Register(ctx, &runnerpb.RegisterRunnerRequest{
		Address: "addr:1",
	})
	if err != nil {
		t.Fatalf("Register: %v", err)
	}

	if len(pool.GetRunners()) != 1 {
		t.Errorf("ожидался 1 раннер после Register, получено %d", len(pool.GetRunners()))
	}

	_, err = r.Unregister(ctx, &runnerpb.UnregisterRunnerRequest{
		Address: "addr:1",
	})
	if err != nil {
		t.Fatalf("Unregister: %v", err)
	}

	if len(pool.GetRunners()) != 0 {
		t.Errorf("ожидалось 0 раннеров после Unregister, получено %d", len(pool.GetRunners()))
	}
}

func TestRegistry_Register_emptyAddress(t *testing.T) {
	pool := NewPool(nil)
	r := NewRegistry(pool)
	ctx := context.Background()

	_, _ = r.Register(ctx, &runnerpb.RegisterRunnerRequest{
		Address: "",
	})
	if len(pool.GetRunners()) != 0 {
		t.Error("пустой адрес не должен добавляться")
	}
}

func TestRegistry_Register_nilRequest(t *testing.T) {
	pool := NewPool(nil)
	r := NewRegistry(pool)
	_, err := r.Register(context.Background(), nil)
	if err != nil {
		t.Fatalf("Register(nil) не должен возвращать ошибку: %v", err)
	}
}
