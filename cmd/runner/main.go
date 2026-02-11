package main

import (
	"context"
	"fmt"
	"github.com/magomedcoder/legion/api/pb/runnerpb"
	"github.com/magomedcoder/legion/pkg/logger"
	"github.com/magomedcoder/legion/runner"
	"github.com/magomedcoder/legion/runner/config"
	"github.com/magomedcoder/legion/runner/gpu"
	"github.com/magomedcoder/legion/runner/provider"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		logger.Default.SetLevel(logger.LevelInfo)
		logger.E("Ошибка загрузки конфигурации: %v", err)
		os.Exit(1)
	}

	logger.Default.SetLevel(logger.ParseLevel(cfg.Log.Level))

	logger.I("Запуск раннера")

	textProvider, err := provider.NewTextProvider(cfg)
	if err != nil {
		logger.E("Движок текста: %v", err)
		os.Exit(1)
	}

	gpuCollector := gpu.NewCollector()
	runnerServer := runner.NewServer(textProvider, gpuCollector)

	lis, err := net.Listen("tcp", cfg.ListenAddr)
	if err != nil {
		logger.E("Ошибка слушателя: %v", err)
		os.Exit(1)
	}
	defer lis.Close()

	grpcServer := grpc.NewServer()
	runnerpb.RegisterRunnerServiceServer(grpcServer, runnerServer)

	go func() {
		logger.I("Раннер слушает на %s", cfg.ListenAddr)
		if err := grpcServer.Serve(lis); err != nil {
			logger.E("Ошибка gRPC: %v", err)
			os.Exit(1)
		}
	}()

	if cfg.CoreAddr != "" && cfg.ListenAddr != "" {
		if err := registerWithCore(cfg.CoreAddr, cfg.ListenAddr); err != nil {
			logger.W("Регистрация в ядре не удалась: %v", err)
		} else {
			logger.I("Зарегистрирован в ядре %s как %s", cfg.CoreAddr, cfg.ListenAddr)
			defer unregisterFromCore(cfg.CoreAddr, cfg.ListenAddr)
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
