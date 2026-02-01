package main

import (
	"context"
	"fmt"
	"github.com/magomedcoder/legion/internal/runner/service"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/magomedcoder/legion/api/pb/runnerpb"
	"github.com/magomedcoder/legion/internal/runner"
	"github.com/magomedcoder/legion/internal/runner/provider"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type config struct {
	ollamaBaseURL string
	ollamaModel   string

	coreAddr   string
	listenAddr string
}

func loadConfig() *config {
	c := &config{
		ollamaBaseURL: "http://127.0.0.1:11434",
		ollamaModel:   "llama3.2:1b",

		coreAddr:   "127.0.0.1:50051",
		listenAddr: "127.0.0.1:50052",
	}

	return c
}

func main() {
	cfg := loadConfig()

	ollamaSvc := service.NewOllamaService(cfg.ollamaBaseURL, cfg.ollamaModel)
	textProvider := provider.NewText(ollamaSvc)
	runnerServer := runner.NewServer(textProvider)

	lis, err := net.Listen("tcp", cfg.listenAddr)
	if err != nil {
		log.Fatalf("Ошибка слушателя: %v", err)
	}
	defer lis.Close()

	grpcServer := grpc.NewServer()
	runnerpb.RegisterRunnerServiceServer(grpcServer, runnerServer)

	go func() {
		log.Printf("Раннер слушает на %s", cfg.listenAddr)
		if err := grpcServer.Serve(lis); err != nil {
			log.Fatalf("Ошибка gRPC: %v", err)
		}
	}()

	if cfg.coreAddr != "" && cfg.listenAddr != "" {
		if err := registerWithCore(cfg.coreAddr, cfg.listenAddr); err != nil {
			log.Printf("Регистрация в ядре не удалась: %v", err)
		} else {
			log.Printf("Зарегистрирован в ядре %s как %s", cfg.coreAddr, cfg.listenAddr)
			defer unregisterFromCore(cfg.coreAddr, cfg.listenAddr)
		}
	}

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	grpcServer.GracefulStop()
	log.Println("Раннер остановлен")
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
		log.Printf("Unregister: подключение к ядру: %v", err)
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
