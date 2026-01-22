package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"

	"github.com/magomedcoder/assist/api/pb"
	"github.com/magomedcoder/assist/config"
	"github.com/magomedcoder/assist/internal/handler"
	"github.com/magomedcoder/assist/internal/repository/postgres"
	"github.com/magomedcoder/assist/internal/service"
	"github.com/magomedcoder/assist/internal/usecase"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
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

	jwtService := service.NewJWTService(cfg)
	passwordService := service.NewPasswordService()

	authUseCase := usecase.NewAuthUseCase(userRepo, tokenRepo, jwtService, passwordService)

	authHandler := handler.NewAuthHandler(authUseCase)

	grpcServer := grpc.NewServer()

	pb.RegisterAuthServiceServer(grpcServer, authHandler)

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
