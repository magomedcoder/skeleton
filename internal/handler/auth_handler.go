package handler

import (
	"context"
	"strings"

	"github.com/magomedcoder/legion/api/pb/authpb"
	"github.com/magomedcoder/legion/internal/usecase"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
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
	user, accessToken, refreshToken, err := a.authUseCase.Login(
		ctx,
		req.Email,
		req.Password,
	)
	if err != nil {
		return nil, status.Error(codes.Unauthenticated, err.Error())
	}

	return &authpb.LoginResponse{
		User:         a.userToProto(user),
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

func (a *AuthHandler) RefreshToken(ctx context.Context, req *authpb.RefreshTokenRequest) (*authpb.RefreshTokenResponse, error) {
	accessToken, refreshToken, err := a.authUseCase.RefreshToken(ctx, req.RefreshToken)
	if err != nil {
		return nil, status.Error(codes.Unauthenticated, err.Error())
	}

	return &authpb.RefreshTokenResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

func (a *AuthHandler) Logout(ctx context.Context, req *authpb.LogoutRequest) (*authpb.LogoutResponse, error) {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return nil, status.Error(codes.Unauthenticated, "метаданные не предоставлены")
	}

	authHeaders := md.Get("authorization")
	if len(authHeaders) == 0 {
		return nil, status.Error(codes.Unauthenticated, "заголовок авторизации не предоставлен")
	}

	authHeader := authHeaders[0]
	if !strings.HasPrefix(authHeader, "Bearer ") {
		return nil, status.Error(codes.Unauthenticated, "неверный формат заголовка авторизации")
	}

	token := strings.TrimPrefix(authHeader, "Bearer ")

	user, err := a.authUseCase.ValidateToken(ctx, token)
	if err != nil {
		return nil, status.Error(codes.Unauthenticated, err.Error())
	}

	if err := a.authUseCase.Logout(ctx, user.Id); err != nil {
		return nil, status.Error(codes.Internal, "не удалось выйти из системы")
	}

	return &authpb.LogoutResponse{
		Success: true,
	}, nil
}
