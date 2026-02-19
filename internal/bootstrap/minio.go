package bootstrap

import (
	"context"
	"errors"
	"fmt"
	"github.com/magomedcoder/legion/internal/config"
	"github.com/magomedcoder/legion/pkg/logger"
	"github.com/magomedcoder/legion/pkg/minio"
)

func EnsureMinioBucket(ctx context.Context, conf *config.Config, client minio.IMinio) error {
	if client == nil {
		return errors.New("minio")
	}

	bucket := conf.Minio.Bucket

	if bucket == "" {
		bucket = "legion"
	}

	if err := client.EnsureBucket(ctx, bucket); err != nil {
		return fmt.Errorf("minio: %w", err)
	}
	logger.D("Бакет MinIO %s готов", bucket)

	return nil
}
