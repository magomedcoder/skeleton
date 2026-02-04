package handler

import (
	"context"
	"github.com/magomedcoder/legion/internal/config"

	"github.com/magomedcoder/legion/api/pb/authpb"
	"github.com/magomedcoder/legion/internal/mappers"
	"github.com/magomedcoder/legion/internal/usecase"
	"github.com/magomedcoder/legion/pkg/logger"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type AuthHandler struct {
	authpb.UnimplementedAuthServiceServer
	authUseCase *usecase.AuthUseCase
	cfg         *config.Config
}

func NewAuthHandler(cfg *config.Config, authUseCase *usecase.AuthUseCase) *AuthHandler {
	return &AuthHandler{
		cfg:         cfg,
		authUseCase: authUseCase,
	}
}

func (a *AuthHandler) Login(ctx context.Context, req *authpb.LoginRequest) (*authpb.LoginResponse, error) {
	logger.D("AuthHandler: вход пользователя %s", req.Username)
	user, accessToken, refreshToken, err := a.authUseCase.Login(ctx, req.Username, req.Password)
	if err != nil {
		logger.W("AuthHandler: ошибка входа: %v", err)
		return nil, ToStatusError(codes.Unauthenticated, err)
	}
	logger.I("AuthHandler: вход выполнен успешно")

	return &authpb.LoginResponse{
		User:         mappers.UserToProto(user),
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

func (a *AuthHandler) RefreshToken(ctx context.Context, req *authpb.RefreshTokenRequest) (*authpb.RefreshTokenResponse, error) {
	logger.D("AuthHandler: обновление токена")
	accessToken, refreshToken, err := a.authUseCase.RefreshToken(ctx, req.RefreshToken)
	if err != nil {
		logger.W("AuthHandler: ошибка обновления токена: %v", err)
		return nil, ToStatusError(codes.Unauthenticated, err)
	}
	logger.I("AuthHandler: токен обновлён")

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
	logger.D("AuthHandler: выход пользователя %d", user.Id)
	if err := a.authUseCase.Logout(ctx, user.Id); err != nil {
		logger.E("AuthHandler: ошибка выхода: %v", err)
		return nil, status.Error(codes.Internal, "не удалось выйти из системы")
	}
	logger.I("AuthHandler: выход выполнен")

	return &authpb.LogoutResponse{
		Success: true,
	}, nil
}

func (a *AuthHandler) ChangePassword(ctx context.Context, req *authpb.ChangePasswordRequest) (*authpb.ChangePasswordResponse, error) {
	user, err := GetUserFromContext(ctx, a.authUseCase)
	if err != nil {
		return nil, err
	}
	logger.D("AuthHandler: смена пароля пользователя %d", user.Id)
	if err := a.authUseCase.ChangePassword(ctx, user.Id, req.OldPassword, req.NewPassword); err != nil {
		logger.W("AuthHandler: ошибка смены пароля: %v", err)
		return nil, ToStatusError(codes.InvalidArgument, err)
	}
	logger.I("AuthHandler: пароль изменён")

	return &authpb.ChangePasswordResponse{Success: true}, nil
}

func (a *AuthHandler) CheckVersion(ctx context.Context, req *authpb.CheckVersionRequest) (*authpb.CheckVersionResponse, error) {
	clientBuild := req.GetClientBuild()
	compatible := clientBuild >= a.cfg.MinClientBuild

	msg := ""
	if !compatible {
		msg = "Версия приложения несовместима с сервером"
	}

	return &authpb.CheckVersionResponse{
		Compatible: compatible,
		Message:    msg,
	}, nil
}
