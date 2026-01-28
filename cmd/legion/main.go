package main

import (
	"context"
	"fmt"
	"github.com/magomedcoder/legion/api/pb/authpb"
	"github.com/magomedcoder/legion/api/pb/chatpb"
	"github.com/magomedcoder/legion/api/pb/userpb"
	"github.com/magomedcoder/legion/config"
	"github.com/magomedcoder/legion/internal/handler"
	"github.com/magomedcoder/legion/internal/repository"
	"github.com/magomedcoder/legion/internal/repository/postgres"
	"github.com/magomedcoder/legion/internal/service"
	"github.com/magomedcoder/legion/internal/usecase"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Ошибка загрузки конфигурации: %v", err)
	}

	ctx := context.Background()
	db, err := postgres.NewDB(ctx, cfg.Database.DSN)
	if err != nil {
		log.Fatalf("Ошибка подключения к базе данных: %v", err)
	}
	defer db.Close(ctx)

	userRepo := postgres.NewUserRepository(db)
	tokenRepo := postgres.NewTokenRepository(db)
	sessionRepo := postgres.NewChatSessionRepository(db)
	messageRepo := postgres.NewMessageRepository(db)

	jwtService := service.NewJWTService(cfg)
	ollamaRepo := repository.NewOllamaRepository(cfg.Ollama.BaseURL, cfg.Ollama.Model)

	authUseCase := usecase.NewAuthUseCase(userRepo, tokenRepo, jwtService)
	chatUseCase := usecase.NewChatUseCase(sessionRepo, messageRepo, ollamaRepo)
	userUseCase := usecase.NewUserUseCase(userRepo, tokenRepo, jwtService)

	authHandler := handler.NewAuthHandler(authUseCase)
	chatHandler := handler.NewChatHandler(chatUseCase, authUseCase)
	userHandler := handler.NewUserHandler(userUseCase, authUseCase)

	grpcServer := grpc.NewServer()

	authpb.RegisterAuthServiceServer(grpcServer, authHandler)
	chatpb.RegisterChatServiceServer(grpcServer, chatHandler)
	userpb.RegisterUserServiceServer(grpcServer, userHandler)

	reflection.Register(grpcServer)

	addr := fmt.Sprintf("%s:%s", cfg.Server.Host, cfg.Server.Port)
	listener, err := net.Listen("tcp", addr)
	if err != nil {
		log.Fatalf("Ошибка запуска сервера на адресе %s: %v", addr, err)
	}

	log.Printf("запущен на %s", addr)

	go func() {
		if err := grpcServer.Serve(listener); err != nil {
			log.Fatalf("Ошибка работы сервера: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	grpcServer.GracefulStop()
	log.Println("Сервер остановлен")
}
