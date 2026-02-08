package handler

import (
	"context"
	"github.com/magomedcoder/skeleton/internal/middleware"
	error2 "github.com/magomedcoder/skeleton/pkg/error"
	"strconv"

	"github.com/magomedcoder/skeleton/api/pb/userpb"
	"github.com/magomedcoder/skeleton/internal/mappers"
	"github.com/magomedcoder/skeleton/internal/usecase"
	"github.com/magomedcoder/skeleton/pkg/logger"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type UserHandler struct {
	userpb.UnimplementedUserServiceServer
	userUseCase *usecase.UserUseCase
	authUseCase usecase.TokenValidator
}

func NewUserHandler(userUseCase *usecase.UserUseCase, authUseCase usecase.TokenValidator) *UserHandler {
	return &UserHandler{
		userUseCase: userUseCase,
		authUseCase: authUseCase,
	}
}

func (u *UserHandler) GetUsers(ctx context.Context, req *userpb.GetUsersRequest) (*userpb.GetUsersResponse, error) {
	if err := middleware.RequireAdmin(ctx, u.authUseCase); err != nil {
		return nil, err
	}
	logger.D("UserHandler: получение пользователей page=%d", req.Page)
	users, total, err := u.userUseCase.GetUsers(ctx, req.Page, req.PageSize)
	if err != nil {
		logger.E("UserHandler: ошибка получения пользователей: %v", err)
		return nil, error2.ToStatusError(codes.Internal, err)
	}
	logger.V("UserHandler: получено пользователей: %d", len(users))

	resp := &userpb.GetUsersResponse{
		Total: total,
	}
	for _, user := range users {
		resp.Users = append(resp.Users, mappers.UserToProto(user))
	}

	return resp, nil
}

func (u *UserHandler) CreateUser(ctx context.Context, req *userpb.CreateUserRequest) (*userpb.CreateUserResponse, error) {
	if err := middleware.RequireAdmin(ctx, u.authUseCase); err != nil {
		return nil, err
	}
	logger.I("UserHandler: создание пользователя %s", req.Username)
	user, err := u.userUseCase.CreateUser(ctx, req.Username, req.Password, req.Name, req.Surname, req.Role)
	if err != nil {
		logger.W("UserHandler: ошибка создания пользователя: %v", err)
		return nil, error2.ToStatusError(codes.InvalidArgument, err)
	}
	logger.I("UserHandler: пользователь создан")

	return &userpb.CreateUserResponse{User: mappers.UserToProto(user)}, nil
}

func (u *UserHandler) EditUser(ctx context.Context, req *userpb.EditUserRequest) (*userpb.EditUserResponse, error) {
	if err := middleware.RequireAdmin(ctx, u.authUseCase); err != nil {
		return nil, err
	}
	if _, err := strconv.Atoi(req.Id); err != nil {
		logger.W("UserHandler: неверный id пользователя: %s", req.Id)
		return nil, status.Error(codes.InvalidArgument, "неверный id пользователя")
	}
	logger.D("UserHandler: обновление пользователя %s", req.Id)
	user, err := u.userUseCase.EditUser(ctx, req.Id, req.Username, req.Password, req.Name, req.Surname, req.Role)
	if err != nil {
		logger.W("UserHandler: ошибка обновления пользователя: %v", err)
		return nil, error2.ToStatusError(codes.InvalidArgument, err)
	}
	logger.I("UserHandler: пользователь обновлён")

	return &userpb.EditUserResponse{User: mappers.UserToProto(user)}, nil
}
