package handler

import (
	"context"
	"testing"

	"github.com/magomedcoder/legion/api/pb/userpb"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/usecase"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)


func TestUserHandler_EditUser_invalidId_returnsInvalidArgument(t *testing.T) {
	auth := &fakeAuth{
		user: &domain.User{
			Id:   1,
			Role: domain.UserRoleAdmin,
		},
	}
	h := NewUserHandler(&usecase.UserUseCase{}, auth)
	ctx := context.Background()

	_, err := h.EditUser(ctx, &userpb.EditUserRequest{
		Id:       "not-a-number",
		Username: "u",
	})
	if code := status.Code(err); code != codes.InvalidArgument {
		t.Errorf("EditUser(неверный id): код %v, ожидался InvalidArgument", code)
	}
}
