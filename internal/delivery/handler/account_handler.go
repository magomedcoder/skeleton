package handler

import (
	"context"
	"github.com/magomedcoder/legion/api/pb/accountpb"
	"github.com/magomedcoder/legion/internal/config"
	"github.com/magomedcoder/legion/internal/delivery/middleware"
	"github.com/magomedcoder/legion/internal/usecase"
	error2 "github.com/magomedcoder/legion/pkg/error"
	"github.com/magomedcoder/legion/pkg/logger"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type AccountHandler struct {
	accountpb.UnimplementedAccountServiceServer
	authUseCase *usecase.AuthUseCase
	cfg         *config.Config
}

func NewAccountHandler(cfg *config.Config, authUseCase *usecase.AuthUseCase) *AccountHandler {
	return &AccountHandler{
		cfg:         cfg,
		authUseCase: authUseCase,
	}
}

func (a *AccountHandler) getSession(ctx context.Context) (*middleware.JSession, error) {
	session := middleware.GetSession(ctx)
	if session == nil {
		return nil, status.Error(codes.Unauthenticated, "сессия не найдена")
	}

	return session, nil
}

func (a *AccountHandler) ChangePassword(ctx context.Context, req *accountpb.ChangePasswordRequest) (*accountpb.ChangePasswordResponse, error) {
	session, err := a.getSession(ctx)
	if err != nil {
		return nil, err
	}
	logger.D("AccountHandler: смена пароля пользователя %d", session.Uid)
	if err := a.authUseCase.ChangePassword(ctx, session.Uid, req.OldPassword, req.NewPassword, req.GetCurrentRefreshToken()); err != nil {
		logger.W("AccountHandler: ошибка смены пароля: %v", err)
		return nil, error2.ToStatusError(codes.InvalidArgument, err)
	}
	logger.I("AccountHandler: пароль изменён")

	return &accountpb.ChangePasswordResponse{
		Success: true,
	}, nil
}

func (a *AccountHandler) GetDevices(ctx context.Context, req *accountpb.GetDevicesRequest) (*accountpb.GetDevicesResponse, error) {
	session, err := a.getSession(ctx)
	if err != nil {
		return nil, err
	}

	tokens, err := a.authUseCase.GetDevices(ctx, session.Uid)
	if err != nil {
		logger.E("AccountHandler: ошибка списка устройств: %v", err)
		return nil, status.Error(codes.Internal, "не удалось получить список устройств")
	}

	devices := make([]*accountpb.Device, 0, len(tokens))
	for _, t := range tokens {
		devices = append(devices, &accountpb.Device{
			Id:               int32(t.Id),
			CreatedAtSeconds: t.CreatedAt.Unix(),
		})
	}

	return &accountpb.GetDevicesResponse{
		Devices: devices,
	}, nil
}

func (a *AccountHandler) RevokeDevice(ctx context.Context, req *accountpb.RevokeDeviceRequest) (*accountpb.RevokeDeviceResponse, error) {
	session, err := a.getSession(ctx)
	if err != nil {
		return nil, err
	}

	if err := a.authUseCase.RevokeDevice(ctx, session.Uid, int(req.GetDeviceId())); err != nil {
		logger.W("AccountHandler: ошибка отзыва устройства: %v", err)
		return nil, error2.ToStatusError(codes.NotFound, err)
	}

	logger.I("AccountHandler: устройство %d отозвано", req.GetDeviceId())
	return &accountpb.RevokeDeviceResponse{
		Success: true,
	}, nil
}
