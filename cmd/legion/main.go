package main

import (
	"context"
	"fmt"
	"github.com/magomedcoder/legion/internal/config"
	"net"
	"os"
	"os/signal"
	"syscall"

	"github.com/magomedcoder/legion"
	"github.com/magomedcoder/legion/api/pb/authpb"
	"github.com/magomedcoder/legion/api/pb/chatpb"
	"github.com/magomedcoder/legion/api/pb/runnerpb"
	"github.com/magomedcoder/legion/api/pb/userpb"
	"github.com/magomedcoder/legion/internal/bootstrap"
	"github.com/magomedcoder/legion/internal/handler"
	"github.com/magomedcoder/legion/internal/repository/postgres"
	"github.com/magomedcoder/legion/internal/runner"
	"github.com/magomedcoder/legion/internal/service"
	"github.com/magomedcoder/legion/internal/usecase"
	"github.com/magomedcoder/legion/pkg/logger"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		logger.Default.SetLevel(logger.LevelInfo)
		logger.E("Ошибка загрузки конфигурации: %v", err)
		os.Exit(1)
	}

	logger.Default.SetLevel(logger.ParseLevel(cfg.Log.Level))

	logger.I("Запуск приложения")
	ctx := context.Background()

	if err := bootstrap.CheckDatabase(ctx, cfg.Database.DSN); err != nil {
		logger.E("Ошибка инициализации базы данных: %v", err)
		os.Exit(1)
	}
	logger.D("База данных доступна")

	db, err := postgres.NewDB(ctx, cfg.Database.DSN)
	if err != nil {
		logger.E("Ошибка подключения к базе данных: %v", err)
		os.Exit(1)
	}
	defer db.Close()
	logger.I("Подключение к базе данных установлено")

	if err := bootstrap.RunMigrations(ctx, db, legion.Postgres); err != nil {
		logger.E("Ошибка применения миграций: %v", err)
		os.Exit(1)
	}
	logger.D("Миграции применены")

	userRepo := postgres.NewUserRepository(db)
	tokenRepo := postgres.NewTokenRepository(db)
	sessionRepo := postgres.NewChatSessionRepository(db)
	messageRepo := postgres.NewMessageRepository(db)
	fileRepo := postgres.NewFileRepository(db)

	jwtService := service.NewJWTService(cfg)

	if err := bootstrap.CreateFirstUser(ctx, userRepo, jwtService); err != nil {
		logger.E("Ошибка создания первого пользователя: %v", err)
		os.Exit(1)
	}
	logger.D("Первый пользователь проверен/создан")

	runnerPool := runner.NewPool(cfg.Runners.Addresses)
	authUseCase := usecase.NewAuthUseCase(userRepo, tokenRepo, jwtService)
	chatUseCase := usecase.NewChatUseCase(sessionRepo, messageRepo, fileRepo, runnerPool, cfg.Attachments.SaveDir)
	userUseCase := usecase.NewUserUseCase(userRepo, tokenRepo, jwtService)

	authHandler := handler.NewAuthHandler(cfg, authUseCase)
	chatHandler := handler.NewChatHandler(chatUseCase, authUseCase)
	userHandler := handler.NewUserHandler(userUseCase, authUseCase)

	grpcServer := grpc.NewServer()

	authpb.RegisterAuthServiceServer(grpcServer, authHandler)
	chatpb.RegisterChatServiceServer(grpcServer, chatHandler)
	userpb.RegisterUserServiceServer(grpcServer, userHandler)
	runnerpb.RegisterRunnerAdminServiceServer(grpcServer, handler.NewRunnerHandler(runnerPool, authUseCase))
	runnerpb.RegisterRunnerServiceServer(grpcServer, runner.NewRegistry(runnerPool))

	reflection.Register(grpcServer)

	addr := fmt.Sprintf("%s:%s", cfg.Server.Host, cfg.Server.Port)
	listener, err := net.Listen("tcp", addr)
	if err != nil {
		logger.E("Ошибка запуска сервера на адресе %s: %v", addr, err)
		os.Exit(1)
	}

	logger.I("Сервер запущен на %s", addr)

	go func() {
		if err := grpcServer.Serve(listener); err != nil {
			logger.E("Ошибка работы сервера: %v", err)
			os.Exit(1)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	grpcServer.GracefulStop()
	logger.I("Сервер остановлен")
}
