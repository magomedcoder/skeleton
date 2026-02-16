package process

import (
	"context"
	"time"

	"github.com/magomedcoder/legion/internal/config"
	redisRepo "github.com/magomedcoder/legion/internal/repository/redis_repository"
	"github.com/magomedcoder/legion/pkg/logger"
)

const healthReportInterval = 10 * time.Second

type HealthReporter struct {
	Conf            *config.Config
	ServerCacheRepo *redisRepo.ServerCacheRepository
}

func NewHealthReporter(conf *config.Config, serverCacheRepo *redisRepo.ServerCacheRepository) *HealthReporter {
	return &HealthReporter{
		Conf:            conf,
		ServerCacheRepo: serverCacheRepo,
	}
}

func (r *HealthReporter) Setup(ctx context.Context) error {
	ticker := time.NewTicker(healthReportInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return nil
		case <-ticker.C:
			if err := r.ServerCacheRepo.Set(ctx, r.Conf.ServerId(), time.Now().Unix()); err != nil {
				logger.E("Ошибка отчёта подписки состояния grpc-потока: %s", err.Error())
			}
		}
	}
}
