package main

import (
	"context"
	"fmt"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/magomedcoder/legion/api/pb/runnerpb"
	"github.com/magomedcoder/legion/internal/runner"
	"github.com/magomedcoder/legion/internal/runner/provider"
	"github.com/magomedcoder/legion/internal/runner/service"
	"github.com/magomedcoder/legion/pkg/logger"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type config struct {
	ollamaBaseURL string
	ollamaModel   string
	coreAddr      string
	listenAddr    string
	logLevel      string
}

func loadConfig() *config {
	c := &config{
		ollamaBaseURL: "http://127.0.0.1:11434",
		ollamaModel:   "llama3.2:1b",
		coreAddr:      "127.0.0.1:50051",
		listenAddr:    "127.0.0.1:50052",
		logLevel:      "info",
	}

	return c
}

func main() {
	cfg := loadConfig()
	logger.Default.SetLevel(logger.ParseLevel(cfg.logLevel))

	logger.I("Запуск раннера")

	ollamaSvc := service.NewOllamaService(cfg.ollamaBaseURL, cfg.ollamaModel)
	textProvider := provider.NewText(ollamaSvc)
	runnerServer := runner.NewServer(textProvider)

	lis, err := net.Listen("tcp", cfg.listenAddr)
	if err != nil {
		logger.E("Ошибка слушателя: %v", err)
		os.Exit(1)
	}
	defer lis.Close()

	grpcServer := grpc.NewServer()
	runnerpb.RegisterRunnerServiceServer(grpcServer, runnerServer)

	go func() {
		logger.I("Раннер слушает на %s", cfg.listenAddr)
		if err := grpcServer.Serve(lis); err != nil {
			logger.E("Ошибка gRPC: %v", err)
			os.Exit(1)
		}
	}()

	if cfg.coreAddr != "" && cfg.listenAddr != "" {
		if err := registerWithCore(cfg.coreAddr, cfg.listenAddr); err != nil {
			logger.W("Регистрация в ядре не удалась: %v", err)
		} else {
			logger.I("Зарегистрирован в ядре %s как %s", cfg.coreAddr, cfg.listenAddr)
			defer unregisterFromCore(cfg.coreAddr, cfg.listenAddr)
		}
	}

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	grpcServer.GracefulStop()
	logger.I("Раннер остановлен")
}

func registerWithCore(coreAddr, registerAddress string) error {
	conn, err := grpc.NewClient(coreAddr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return fmt.Errorf("подключение к ядру: %w", err)
	}
	defer conn.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client := runnerpb.NewRunnerServiceClient(conn)
	_, err = client.Register(ctx, &runnerpb.RegisterRunnerRequest{
		Address: registerAddress,
	})
	return err
}

func unregisterFromCore(coreAddr, registerAddress string) {
	conn, err := grpc.NewClient(coreAddr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		logger.W("Unregister: подключение к ядру: %v", err)
		return
	}
	defer conn.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client := runnerpb.NewRunnerServiceClient(conn)
	_, _ = client.Unregister(ctx, &runnerpb.UnregisterRunnerRequest{
		Address: registerAddress,
	})
}
