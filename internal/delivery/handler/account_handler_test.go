package handler

import (
	"context"
	"testing"

	"github.com/magomedcoder/legion/api/pb/accountpb"
	"github.com/magomedcoder/legion/internal/config"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestAuthHandler_ChangePassword_noAuth(t *testing.T) {
	h := NewAccountHandler(&config.Config{}, nil)
	_, err := h.ChangePassword(context.Background(), &accountpb.ChangePasswordRequest{})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("ChangePassword: код %v, ожидался Unauthenticated", code)
	}
}

func TestAuthHandler_GetDevices_noAuth(t *testing.T) {
	h := NewAccountHandler(&config.Config{}, nil)
	_, err := h.GetDevices(context.Background(), &accountpb.GetDevicesRequest{})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("GetDevices: код %v, ожидался Unauthenticated", code)
	}
}

func TestAuthHandler_RevokeDevice_noAuth(t *testing.T) {
	h := NewAccountHandler(&config.Config{}, nil)
	_, err := h.RevokeDevice(context.Background(), &accountpb.RevokeDeviceRequest{})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("RevokeDevice: код %v, ожидался Unauthenticated", code)
	}
}
