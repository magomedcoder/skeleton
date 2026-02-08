package handler

import (
	"context"
	"testing"

	"github.com/magomedcoder/legion/api/pb/userpb"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/usecase"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

func TestUserHandler_GetUsers_noAuth(t *testing.T) {
	h := NewUserHandler(&usecase.UserUseCase{}, nil)
	ctx := context.Background()

	_, err := h.GetUsers(ctx, &userpb.GetUsersRequest{})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("GetUsers: код %v, ожидался Unauthenticated", code)
	}
}

func TestUserHandler_GetUsers_nonAdmin_returnsPermissionDenied(t *testing.T) {
	auth := &fakeAuth{user: &domain.User{
		Id:       1,
		Username: "u",
		Role:     domain.UserRoleUser,
	}}
	h := NewUserHandler(&usecase.UserUseCase{}, auth)
	ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "Bearer tok"))

	_, err := h.GetUsers(ctx, &userpb.GetUsersRequest{})
	if code := status.Code(err); code != codes.PermissionDenied {
		t.Errorf("GetUsers(не админ): код %v, ожидался PermissionDenied", code)
	}
}

func TestUserHandler_CreateUser_noAuth(t *testing.T) {
	h := NewUserHandler(&usecase.UserUseCase{}, nil)
	ctx := context.Background()

	_, err := h.CreateUser(ctx, &userpb.CreateUserRequest{
		Username: "u",
		Password: "password123",
	})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("CreateUser: код %v, ожидался Unauthenticated", code)
	}
}

func TestUserHandler_EditUser_noAuth(t *testing.T) {
	h := NewUserHandler(&usecase.UserUseCase{}, nil)
	ctx := context.Background()

	_, err := h.EditUser(ctx, &userpb.EditUserRequest{
		Id:       "1",
		Username: "u",
	})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("EditUser: код %v, ожидался Unauthenticated", code)
	}
}

func TestUserHandler_EditUser_invalidId_returnsInvalidArgument(t *testing.T) {
	auth := &fakeAuth{
		user: &domain.User{
			Id:   1,
			Role: domain.UserRoleAdmin,
		},
	}
	h := NewUserHandler(&usecase.UserUseCase{}, auth)
	ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "Bearer tok"))

	_, err := h.EditUser(ctx, &userpb.EditUserRequest{
		Id:       "not-a-number",
		Username: "u",
	})
	if code := status.Code(err); code != codes.InvalidArgument {
		t.Errorf("EditUser(неверный id): код %v, ожидался InvalidArgument", code)
	}
}
