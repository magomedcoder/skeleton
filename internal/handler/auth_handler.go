package handler

import (
	"context"

	"github.com/magomedcoder/legion/api/pb/authpb"
	"github.com/magomedcoder/legion/internal/mappers"
	"github.com/magomedcoder/legion/internal/usecase"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type AuthHandler struct {
	authpb.UnimplementedAuthServiceServer
	authUseCase *usecase.AuthUseCase
}

func NewAuthHandler(authUseCase *usecase.AuthUseCase) *AuthHandler {
	return &AuthHandler{
		authUseCase: authUseCase,
	}
}

func (a *AuthHandler) Login(ctx context.Context, req *authpb.LoginRequest) (*authpb.LoginResponse, error) {
	user, accessToken, refreshToken, err := a.authUseCase.Login(ctx, req.Username, req.Password)
	if err != nil {
		return nil, ToStatusError(codes.Unauthenticated, err)
	}

	return &authpb.LoginResponse{
		User:         mappers.UserToProto(user),
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

func (a *AuthHandler) RefreshToken(ctx context.Context, req *authpb.RefreshTokenRequest) (*authpb.RefreshTokenResponse, error) {
	accessToken, refreshToken, err := a.authUseCase.RefreshToken(ctx, req.RefreshToken)
	if err != nil {
		return nil, ToStatusError(codes.Unauthenticated, err)
	}

	return &authpb.RefreshTokenResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

func (a *AuthHandler) Logout(ctx context.Context, req *authpb.LogoutRequest) (*authpb.LogoutResponse, error) {
	user, err := GetUserFromContext(ctx, a.authUseCase)
	if err != nil {
		return nil, err
	}

	if err := a.authUseCase.Logout(ctx, user.Id); err != nil {
		return nil, status.Error(codes.Internal, "не удалось выйти из системы")
	}

	return &authpb.LogoutResponse{
		Success: true,
	}, nil
}

func (a *AuthHandler) ChangePassword(ctx context.Context, req *authpb.ChangePasswordRequest) (*authpb.ChangePasswordResponse, error) {
	user, err := GetUserFromContext(ctx, a.authUseCase)
	if err != nil {
		return nil, err
	}

	if err := a.authUseCase.ChangePassword(ctx, user.Id, req.OldPassword, req.NewPassword); err != nil {
		return nil, ToStatusError(codes.InvalidArgument, err)
	}

	return &authpb.ChangePasswordResponse{Success: true}, nil
}
