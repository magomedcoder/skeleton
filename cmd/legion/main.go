package main

import (
	"context"
	"fmt"
	"github.com/magomedcoder/legion"
	"github.com/magomedcoder/legion/api/pb/aichatpb"
	"github.com/magomedcoder/legion/api/pb/authpb"
	"github.com/magomedcoder/legion/api/pb/chatpb"
	"github.com/magomedcoder/legion/api/pb/editorpb"
	"github.com/magomedcoder/legion/api/pb/runnerpb"
	"github.com/magomedcoder/legion/api/pb/searchpb"
	"github.com/magomedcoder/legion/api/pb/userpb"
	"github.com/magomedcoder/legion/internal/bootstrap"
	"github.com/magomedcoder/legion/internal/config"
	"github.com/magomedcoder/legion/internal/handler"
	"github.com/magomedcoder/legion/internal/middleware"
	"github.com/magomedcoder/legion/internal/repository/postgres"
	"github.com/magomedcoder/legion/internal/runner"
	"github.com/magomedcoder/legion/internal/service"
	"github.com/magomedcoder/legion/internal/usecase"
	"github.com/magomedcoder/legion/pkg/logger"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"net"
	"os"
	"os/signal"
	"syscall"
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
	sqlDB, errDB := db.DB()
	if errDB != nil {
		logger.E("Ошибка получения *sql.DB: %v", errDB)
		os.Exit(1)
	}
	defer sqlDB.Close()
	logger.I("Подключение к базе данных установлено")

	if err := bootstrap.RunMigrations(ctx, db, legion.Postgres); err != nil {
		logger.E("Ошибка применения миграций: %v", err)
		os.Exit(1)
	}
	logger.D("Миграции применены")

	userRepo := postgres.NewUserRepository(db)
	userSessionRepo := postgres.NewUserSessionRepository(db)
	aiChatSessionRepo := postgres.NewAIChatSessionRepository(db)
	messageRepo := postgres.NewMessageRepository(db)
	chatRepo := postgres.NewChatRepository(db)
	chatMessageRepo := postgres.NewChatMessageRepository(db)
	fileRepo := postgres.NewFileRepository(db)

	jwtService := service.NewJWTService(cfg)

	if err := bootstrap.CreateFirstUser(ctx, userRepo, jwtService); err != nil {
		logger.E("Ошибка создания первого пользователя: %v", err)
		os.Exit(1)
	}
	logger.D("Первый пользователь проверен/создан")

	runnerPool := runner.NewPool(cfg.Runners.Addresses)
	authUseCase := usecase.NewAuthUseCase(userRepo, userSessionRepo, jwtService)
	chatUseCase := usecase.NewAIChatUseCase(aiChatSessionRepo, messageRepo, fileRepo, runnerPool, cfg.Attachments.SaveDir)
	userChatUseCase := usecase.NewChatUseCase(chatRepo, chatMessageRepo, userRepo)
	editorUseCase := usecase.NewEditorUseCase(runnerPool)
	userUseCase := usecase.NewUserUseCase(userRepo, userSessionRepo, jwtService)
	searchUseCase := usecase.NewSearchUseCase(userRepo)

	authHandler := handler.NewAuthHandler(cfg, authUseCase)
	chatHandler := handler.NewAIChatHandler(chatUseCase, authUseCase)
	userChatHandler := handler.NewChatHandler(userChatUseCase, authUseCase)
	editorHandler := handler.NewEditorHandler(editorUseCase, authUseCase)
	userHandler := handler.NewUserHandler(userUseCase, authUseCase)
	searchHandler := handler.NewSearchHandler(searchUseCase, authUseCase)

	authMiddleware := middleware.NewMiddleware(authUseCase)

	grpcServer := grpc.NewServer(
		grpc.ChainUnaryInterceptor(authMiddleware.UnaryAuthInterceptor),
		grpc.ChainStreamInterceptor(authMiddleware.StreamAuthInterceptor),
	)

	authpb.RegisterAuthServiceServer(grpcServer, authHandler)
	aichatpb.RegisterAIChatServiceServer(grpcServer, chatHandler)
	chatpb.RegisterChatServiceServer(grpcServer, userChatHandler)
	editorpb.RegisterEditorServiceServer(grpcServer, editorHandler)
	userpb.RegisterUserServiceServer(grpcServer, userHandler)
	searchpb.RegisterSearchServiceServer(grpcServer, searchHandler)
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
