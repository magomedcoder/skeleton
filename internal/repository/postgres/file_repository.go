package postgres

import (
	"context"
	"errors"

	"github.com/magomedcoder/legion/internal/domain"
	"gorm.io/gorm"
)

type fileRepository struct {
	db *gorm.DB
}

func NewFileRepository(db *gorm.DB) domain.FileRepository {
	return &fileRepository{db: db}
}

func (r *fileRepository) Create(ctx context.Context, file *domain.File) error {
	m := fileDomainToModel(file)
	return r.db.WithContext(ctx).Create(m).Error
}

func (r *fileRepository) GetById(ctx context.Context, id string) (*domain.File, error) {
	var m fileModel
	if err := r.db.WithContext(ctx).Where("id = ?", id).First(&m).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, err
		}
		return nil, err
	}

	return fileModelToDomain(&m), nil
}
