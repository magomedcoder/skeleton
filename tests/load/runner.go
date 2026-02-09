package load

import (
	"context"
	"fmt"
	"math/rand"
	"sync"
	"time"

	"github.com/magomedcoder/legion/api/pb/aichatpb"
	"github.com/magomedcoder/legion/api/pb/authpb"
	"github.com/magomedcoder/legion/api/pb/commonpb"
	"github.com/magomedcoder/legion/api/pb/userpb"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
)

type Config struct {
	Target   string
	Duration time.Duration
	Workers  int
	Username string
	Password string
}

func Run(ctx context.Context, cfg Config) (*Report, error) {
	if cfg.Workers <= 0 {
		cfg.Workers = 1
	}

	if cfg.Duration <= 0 {
		cfg.Duration = 10 * time.Second
	}

	if cfg.Username == "" {
		cfg.Username = "legion"
	}

	if cfg.Password == "" {
		cfg.Password = "password"
	}

	conn, err := grpc.NewClient(cfg.Target, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return nil, fmt.Errorf("подключение к %s: %w", cfg.Target, err)
	}
	defer conn.Close()

	authClient := authpb.NewAuthServiceClient(conn)
	loginResp, err := authClient.Login(ctx, &authpb.LoginRequest{
		Username: cfg.Username,
		Password: cfg.Password,
	})
	if err != nil {
		return nil, fmt.Errorf("login: %w", err)
	}

	accessToken := loginResp.GetAccessToken()
	if accessToken == "" {
		return nil, fmt.Errorf("пустой access_token в ответе Login")
	}

	aiClient := aichatpb.NewAIChatServiceClient(conn)
	userClient := userpb.NewUserServiceClient(conn)

	deadline := time.Now().Add(cfg.Duration)
	runCtx, cancel := context.WithDeadline(ctx, deadline)
	defer cancel()

	globalStats := NewStats()
	var wg sync.WaitGroup
	for w := 0; w < cfg.Workers; w++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			workerStats := NewStats()

			for time.Now().Before(deadline) && runCtx.Err() == nil {
				start := time.Now()
				err := callRandomRPC(runCtx, accessToken, aiClient, userClient)
				workerStats.Record(time.Since(start), err != nil)
			}

			globalStats.Merge(workerStats)
		}()
	}
	wg.Wait()

	actualDuration := time.Since(deadline.Add(-cfg.Duration))
	if actualDuration > cfg.Duration {
		actualDuration = cfg.Duration
	}

	r := globalStats.Report(actualDuration)

	return &r, nil
}

func callRandomRPC(
	ctx context.Context,
	accessToken string,
	aiClient aichatpb.AIChatServiceClient,
	userClient userpb.UserServiceClient,
) error {
	ctx = metadata.AppendToOutgoingContext(ctx, "authorization", "Bearer "+accessToken)

	switch rand.Intn(3) {
	case 0:
		_, err := aiClient.GetModels(ctx, &commonpb.Empty{})
		return err
	case 1:
		_, err := aiClient.GetSessions(ctx, &aichatpb.GetSessionsRequest{
			Page:     1,
			PageSize: 20,
		})
		return err
	default:
		_, err := userClient.GetUsers(ctx, &userpb.GetUsersRequest{
			Page:     1,
			PageSize: 20,
		})
		return err
	}
}
