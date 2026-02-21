package main

import (
	"context"
	"errors"
	"fmt"
	"github.com/magomedcoder/legion/internal/delivery/event"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/magomedcoder/legion"
	"github.com/magomedcoder/legion/api/pb/accountpb"
	"github.com/magomedcoder/legion/api/pb/aichatpb"
	"github.com/magomedcoder/legion/api/pb/authpb"
	"github.com/magomedcoder/legion/api/pb/chatpb"
	"github.com/magomedcoder/legion/api/pb/editorpb"
	"github.com/magomedcoder/legion/api/pb/projectpb"
	"github.com/magomedcoder/legion/api/pb/runnerpb"
	"github.com/magomedcoder/legion/api/pb/searchpb"
	"github.com/magomedcoder/legion/api/pb/userpb"
	"github.com/magomedcoder/legion/internal/bootstrap"
	"github.com/magomedcoder/legion/internal/config"
	"github.com/magomedcoder/legion/internal/delivery/consume"
	"github.com/magomedcoder/legion/internal/delivery/handler"
	"github.com/magomedcoder/legion/internal/delivery/middleware"
	"github.com/magomedcoder/legion/internal/delivery/process"
	"github.com/magomedcoder/legion/internal/pkg/socket"
	"github.com/magomedcoder/legion/internal/repository/postgres"
	"github.com/magomedcoder/legion/internal/repository/redis_repository"
	"github.com/magomedcoder/legion/internal/service"
	"github.com/magomedcoder/legion/internal/usecase"
	"github.com/magomedcoder/legion/pkg/logger"
	"github.com/magomedcoder/legion/runner"
	"golang.org/x/sync/errgroup"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

func main() {
	conf, err := config.Load()
	if err != nil {
		logger.Default.SetLevel(logger.LevelInfo)
		logger.E("Ошибка загрузки конфигурации: %v", err)
		os.Exit(1)
	}

	logger.Default.SetLevel(logger.ParseLevel(conf.Log.Level))

	logger.I("Запуск приложения")
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	if err := bootstrap.CheckDatabase(ctx, conf.Postgres.GetDsn()); err != nil {
		logger.E("Ошибка инициализации базы данных: %v", err)
		os.Exit(1)
	}

	minioClient := config.NewMinioClient(conf)

	if err := bootstrap.EnsureMinioBucket(ctx, conf, minioClient); err != nil {
		logger.E("Ошибка инициализации MinIO: %v", err)
		os.Exit(1)
	}

	db, err := postgres.NewDB(ctx, conf.Postgres.GetDsn())
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

	if err := bootstrap.RunMigrations(ctx, db, legion.Postgres); err != nil {
		logger.E("Ошибка применения миграций: %v", err)
		os.Exit(1)
	}

	userRepo := postgres.NewUserRepository(db)
	userSessionRepo := postgres.NewUserSessionRepository(db)
	aiChatSessionRepo := postgres.NewAIChatSessionRepository(db)
	messageRepo := postgres.NewMessageRepository(db)
	chatRepo := postgres.NewChatRepository(db)
	chatMessageRepo := postgres.NewChatMessageRepository(db)
	messageReadRepo := postgres.NewMessageReadRepository(db)
	messageDeletedRepo := postgres.NewMessageDeletedRepository(db)
	fileRepo := postgres.NewFileRepository(db)
	projectRepo := postgres.NewProjectRepository(db)
	projectMemberRepo := postgres.NewProjectMemberRepository(db)
	projectTaskRepo := postgres.NewProjectTaskRepository(db)
	projectTaskCommentRepo := postgres.NewProjectTaskCommentRepository(db)
	projectColumnRepo := postgres.NewProjectColumnRepository(db)
	projectActivityRepo := postgres.NewProjectActivityRepository(db)

	redisClient, err := redis_repository.NewRedisClient(conf)
	if err != nil {
		logger.E("Ошибка подключения к Redis: %v", err)
		os.Exit(1)
	}

	serverCache := redis_repository.NewServerCacheRepository(redisClient)
	clientCache := redis_repository.NewClientCacheRepository(conf, redisClient, serverCache)

	storageUseCase := usecase.NewStorageUseCase(conf, minioClient)

	jwtService := service.NewJWTService(conf)

	if err := bootstrap.CreateFirstUser(ctx, userRepo, jwtService); err != nil {
		logger.E("Ошибка создания первого пользователя: %v", err)
		os.Exit(1)
	}

	runnerPool := runner.NewPool(conf.Runners.Addresses)
	authUseCase := usecase.NewAuthUseCase(userRepo, userSessionRepo, jwtService)
	chatUseCase := usecase.NewChatUseCase(
		chatRepo,
		chatMessageRepo,
		messageReadRepo,
		messageDeletedRepo,
		userRepo,
		usecase.WithChatRedis(redisClient),
		usecase.WithChatServerCache(serverCache),
		usecase.WithChatClientCache(clientCache),
	)
	aiChatUseCase := usecase.NewAIChatUseCase(aiChatSessionRepo, messageRepo, fileRepo, runnerPool, storageUseCase)
	editorUseCase := usecase.NewEditorUseCase(runnerPool)
	userUseCase := usecase.NewUserUseCase(userRepo, userSessionRepo, jwtService)
	searchUseCase := usecase.NewSearchUseCase(userRepo)
	projectUseCase := usecase.NewProjectUseCase(
		projectRepo, projectMemberRepo, projectTaskRepo, projectTaskCommentRepo, projectColumnRepo, projectActivityRepo, userRepo,
		usecase.WithProjectRedis(redisClient),
		usecase.WithProjectServerCache(serverCache),
		usecase.WithProjectClientCache(clientCache),
		usecase.WithProjectConf(conf),
	)

	consumeHandler := &consume.Handler{
		Conf:           conf,
		ClientCache:    clientCache,
		ChatUseCase:    chatUseCase,
		ProjectUseCase: projectUseCase,
	}
	chatSubscribe := consume.NewChatSubscribe(consumeHandler)

	eventHandler := event.NewHandler(redisClient)
	chatEvent := &event.ChatEvent{
		Redis:   redisClient,
		Conf:    conf,
		Handler: eventHandler,
	}

	healthReporter := process.NewHealthReporter(conf, serverCache)
	messageSubscriber := process.NewMessageSubscriber(conf, redisClient, chatSubscribe)
	subServers := &process.SubServers{
		HealthReporter:    healthReporter,
		MessageSubscriber: messageSubscriber,
	}
	processServer := process.NewServer(subServers)

	authHandler := handler.NewAuthHandler(conf, authUseCase)
	accountHandler := handler.NewAccountHandler(conf, authUseCase, clientCache, chatEvent)
	chatHandler := handler.NewAIChatHandler(aiChatUseCase, authUseCase)
	userChatHandler := handler.NewChatHandler(chatUseCase, authUseCase)
	editorHandler := handler.NewEditorHandler(editorUseCase, authUseCase)
	userHandler := handler.NewUserHandler(userUseCase, authUseCase)
	searchHandler := handler.NewSearchHandler(searchUseCase, authUseCase)
	projectHandler := handler.NewProjectHandler(projectUseCase)

	authMiddleware := middleware.NewMiddleware(authUseCase)

	grpcServer := grpc.NewServer(
		grpc.ChainUnaryInterceptor(authMiddleware.UnaryAuthInterceptor),
		grpc.ChainStreamInterceptor(authMiddleware.StreamAuthInterceptor),
	)

	authpb.RegisterAuthServiceServer(grpcServer, authHandler)
	accountpb.RegisterAccountServiceServer(grpcServer, accountHandler)
	aichatpb.RegisterAIChatServiceServer(grpcServer, chatHandler)
	chatpb.RegisterChatServiceServer(grpcServer, userChatHandler)
	editorpb.RegisterEditorServiceServer(grpcServer, editorHandler)
	userpb.RegisterUserServiceServer(grpcServer, userHandler)
	searchpb.RegisterSearchServiceServer(grpcServer, searchHandler)
	projectpb.RegisterProjectServiceServer(grpcServer, projectHandler)
	runnerpb.RegisterRunnerAdminServiceServer(grpcServer, handler.NewRunnerHandler(runnerPool, authUseCase))
	runnerpb.RegisterRunnerServiceServer(grpcServer, runner.NewRegistry(runnerPool, conf.Runners.RegistrationToken))

	reflection.Register(grpcServer)

	addr := fmt.Sprintf("%s:%s", conf.Server.Host, conf.Server.Port)
	listener, err := net.Listen("tcp", addr)
	if err != nil {
		logger.E("Ошибка запуска сервера на адресе %s: %v", addr, err)
		os.Exit(1)
	}
	defer listener.Close()

	logger.I("gRPC сервер слушает на %s (PID: %d)", addr, os.Getpid())

	group, groupCtx := errgroup.WithContext(ctx)

	socket.Initialize(groupCtx, group, func(name string) {
		logger.D("Цикл остановлен: %s", name)
	})

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT)

	time.AfterFunc(3*time.Second, func() {
		processServer.Start(group, groupCtx)
	})

	group.Go(func() error {
		return grpcServer.Serve(listener)
	})

	group.Go(func() error {
		select {
		case <-groupCtx.Done():
			grpcServer.Stop()
			return groupCtx.Err()
		case sig := <-sigCh:
			logger.I("Получен сигнал %v, остановка сервера...", sig)
			cancel()
			grpcServer.Stop()
			return nil
		}
	})

	if err := group.Wait(); err != nil && !errors.Is(err, context.Canceled) {
		logger.E("Остановка сервера: %v", err)
		os.Exit(1)
	}

	logger.I("Сервер остановлен")
}
