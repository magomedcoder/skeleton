package redis_repository

import (
	"context"
	"fmt"
	"github.com/magomedcoder/legion/internal/config"
	"github.com/redis/go-redis/v9"
)

func NewRedisClient(conf *config.Config) (*redis.Client, error) {
	client := redis.NewClient(conf.Redis.Options())
	if _, err := client.Ping(context.TODO()).Result(); err != nil {
		return nil, fmt.Errorf("ошибка подключения к Redis: %w", err)
	}

	return client, nil
}
