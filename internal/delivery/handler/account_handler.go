package handler

import (
	"context"
	"github.com/magomedcoder/legion/api/pb/accountpb"
	"github.com/magomedcoder/legion/internal/config"
	"github.com/magomedcoder/legion/internal/delivery/event"
	"github.com/magomedcoder/legion/internal/delivery/middleware"
	"github.com/magomedcoder/legion/internal/pkg/socket"
	redisRepo "github.com/magomedcoder/legion/internal/repository/redis_repository"
	"github.com/magomedcoder/legion/internal/usecase"
	error2 "github.com/magomedcoder/legion/pkg/error"
	"github.com/magomedcoder/legion/pkg/logger"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"log"
)

type AccountHandler struct {
	accountpb.UnimplementedAccountServiceServer
	cfg             *config.Config
	authUseCase     *usecase.AuthUseCase
	ClientCacheRepo *redisRepo.ClientCacheRepository
	Event           *event.ChatEvent
}

func NewAccountHandler(
	cfg *config.Config,
	authUseCase *usecase.AuthUseCase,
	clientCacheRepo *redisRepo.ClientCacheRepository,
	Event *event.ChatEvent,
) *AccountHandler {
	return &AccountHandler{
		cfg:             cfg,
		authUseCase:     authUseCase,
		ClientCacheRepo: clientCacheRepo,
		Event:           Event,
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

func (a *AccountHandler) GetUpdates(stream accountpb.AccountService_GetUpdatesServer) error {
	ctx := stream.Context()

	select {
	case <-ctx.Done():
		log.Println("Запрос был отменен или истекло время")
		return ctx.Err()
	default:
	}

	session, err := a.getSession(ctx)
	if err != nil {
		return status.Errorf(codes.Unauthenticated, "unauthorized")
	}

	conn, err := socket.NewGRPCStreamAdapter(stream)
	if err != nil {
		log.Printf("Account - NewGrpcStreamAdapter: %s", err)
		return err
	}

	err = socket.NewClient(conn, &socket.ClientOption{
		Uid:     session.Uid,
		Channel: socket.Session.Chat,
		Storage: a.ClientCacheRepo,
		Buffer:  10,
	}, socket.NewEvent(
		socket.WithOpenEvent(a.Event.OnOpen),
		socket.WithMessageEvent(a.Event.OnMessage),
		socket.WithCloseEvent(a.Event.OnClose),
	))
	if err != nil {
		log.Printf("Account - NewClient: %s", err)
		return err
	}

	<-ctx.Done()
	return ctx.Err()
}
