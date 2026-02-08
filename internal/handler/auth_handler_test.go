package handler

import (
	"context"
	"testing"

	"github.com/magomedcoder/skeleton/api/pb/authpb"
	"github.com/magomedcoder/skeleton/internal/config"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestAuthHandler_CheckVersion_compatible(t *testing.T) {
	cfg := &config.Config{
		MinClientBuild: 1,
	}
	h := NewAuthHandler(cfg, nil)
	ctx := context.Background()

	resp, err := h.CheckVersion(ctx, &authpb.CheckVersionRequest{
		ClientBuild: 1,
	})
	if err != nil {
		t.Fatalf("CheckVersion: %v", err)
	}

	if !resp.Compatible {
		t.Errorf("ожидалось compatible=true, получено false")
	}

	if resp.Message != "" {
		t.Errorf("ожидалось пустое сообщение, получено %q", resp.Message)
	}

	resp, err = h.CheckVersion(ctx, &authpb.CheckVersionRequest{
		ClientBuild: 2,
	})
	if err != nil {
		t.Fatalf("CheckVersion: %v", err)
	}

	if !resp.Compatible {
		t.Errorf("ожидалось compatible=true, получено false")
	}
}

func TestAuthHandler_CheckVersion_incompatible(t *testing.T) {
	cfg := &config.Config{
		MinClientBuild: 2,
	}
	h := NewAuthHandler(cfg, nil)
	ctx := context.Background()

	resp, err := h.CheckVersion(ctx, &authpb.CheckVersionRequest{
		ClientBuild: 1,
	})
	if err != nil {
		t.Fatalf("CheckVersion: %v", err)
	}

	if resp.Compatible {
		t.Errorf("ожидалось compatible=false, получено true")
	}

	if resp.Message == "" {
		t.Errorf("ожидалось непустое сообщение")
	}
}

func TestAuthHandler_Logout_noAuth(t *testing.T) {
	h := NewAuthHandler(&config.Config{}, nil)
	_, err := h.Logout(context.Background(), &authpb.LogoutRequest{})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("Logout: код %v, ожидался Unauthenticated", code)
	}
}

func TestAuthHandler_ChangePassword_noAuth(t *testing.T) {
	h := NewAuthHandler(&config.Config{}, nil)
	_, err := h.ChangePassword(context.Background(), &authpb.ChangePasswordRequest{})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("ChangePassword: код %v, ожидался Unauthenticated", code)
	}
}

func TestAuthHandler_GetDevices_noAuth(t *testing.T) {
	h := NewAuthHandler(&config.Config{}, nil)
	_, err := h.GetDevices(context.Background(), &authpb.GetDevicesRequest{})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("GetDevices: код %v, ожидался Unauthenticated", code)
	}
}

func TestAuthHandler_RevokeDevice_noAuth(t *testing.T) {
	h := NewAuthHandler(&config.Config{}, nil)
	_, err := h.RevokeDevice(context.Background(), &authpb.RevokeDeviceRequest{})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("RevokeDevice: код %v, ожидался Unauthenticated", code)
	}
}
