package handler

import (
	"context"
	"strconv"

	"github.com/magomedcoder/legion/api/pb/userpb"
	"github.com/magomedcoder/legion/internal/usecase"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type UserHandler struct {
	userpb.UnimplementedUserServiceServer
	userUseCase *usecase.UserUseCase
	authUseCase *usecase.AuthUseCase
}

func NewUserHandler(userUseCase *usecase.UserUseCase, authUseCase *usecase.AuthUseCase) *UserHandler {
	return &UserHandler{
		userUseCase: userUseCase,
		authUseCase: authUseCase,
	}
}


func (u *UserHandler) GetUsers(ctx context.Context, req *userpb.GetUsersRequest) (*userpb.GetUsersResponse, error) {
	if err := requireAdmin(ctx, u.authUseCase); err != nil {
		return nil, err
	}

	users, total, err := u.userUseCase.GetUsers(ctx, req.Page, req.PageSize)
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}

	resp := &userpb.GetUsersResponse{
		Total: total,
	}
	for _, user := range users {
		resp.Users = append(resp.Users, userToProto(user))
	}

	return resp, nil
}

func (u *UserHandler) CreateUser(ctx context.Context, req *userpb.CreateUserRequest) (*userpb.CreateUserResponse, error) {
	if err := requireAdmin(ctx, u.authUseCase); err != nil {
		return nil, err
	}

	user, err := u.userUseCase.CreateUser(ctx, req.Username, req.Password, req.Name, req.Surname, req.Role)
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}

	return &userpb.CreateUserResponse{User: userToProto(user)}, nil
}

func (u *UserHandler) EditUser(ctx context.Context, req *userpb.EditUserRequest) (*userpb.EditUserResponse, error) {
	if err := requireAdmin(ctx, u.authUseCase); err != nil {
		return nil, err
	}

	if _, err := strconv.Atoi(req.Id); err != nil {
		return nil, status.Error(codes.InvalidArgument, "неверный id пользователя")
	}

	user, err := u.userUseCase.EditUser(ctx, req.Id, req.Username, req.Password, req.Name, req.Surname, req.Role)
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}

	return &userpb.EditUserResponse{User: userToProto(user)}, nil
}
