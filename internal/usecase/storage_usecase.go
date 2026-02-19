package usecase

import (
	"context"
	"fmt"
	"path/filepath"

	"github.com/magomedcoder/legion/internal/config"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/pkg/minio"
)

type StorageUseCase struct {
	conf  *config.Config
	minio minio.IMinio
}

func NewStorageUseCase(conf *config.Config, minio minio.IMinio) *StorageUseCase {
	return &StorageUseCase{
		conf:  conf,
		minio: minio,
	}
}

func (s *StorageUseCase) SaveAttachment(ctx context.Context, scope, scopeID, fileName string, content []byte) (*domain.File, error) {
	if s.conf.Minio == nil || s.conf.Minio.Bucket == "" {
		return nil, fmt.Errorf("хранилище вложений не настроено")
	}

	baseName := filepath.Base(fileName)
	if baseName == "" || baseName == "." {
		baseName = "attachment"
	}

	file := domain.NewFile(baseName, "", int64(len(content)), "")
	objectKey := fmt.Sprintf("attachments/%s/%s/%s_%s", scope, scopeID, file.Id, baseName)
	if err := s.minio.Write(s.conf.Minio.Bucket, objectKey, content); err != nil {
		return nil, fmt.Errorf("запись вложения в хранилище: %w", err)
	}

	file.StoragePath = objectKey

	return file, nil
}
