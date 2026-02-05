package postgres

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/magomedcoder/skeleton/internal/domain"
)

type fileRepository struct {
	db *pgxpool.Pool
}

func NewFileRepository(db *pgxpool.Pool) domain.FileRepository {
	return &fileRepository{db: db}
}

func (r *fileRepository) Create(ctx context.Context, file *domain.File) error {
	_, err := r.db.Exec(ctx, `
		INSERT INTO files (id, filename, mime_type, size, storage_path, created_at)
		VALUES ($1, $2, $3, $4, $5, $6)
	`,
		file.Id,
		file.Filename,
		nullString(file.MimeType),
		file.Size,
		file.StoragePath,
		file.CreatedAt,
	)
	return err
}

func (r *fileRepository) GetById(ctx context.Context, id string) (*domain.File, error) {
	var f domain.File
	var mimeType *string
	err := r.db.QueryRow(ctx, `
		SELECT id, filename, mime_type, size, storage_path, created_at
		FROM files
		WHERE id = $1
	`, id).Scan(
		&f.Id,
		&f.Filename,
		&mimeType,
		&f.Size,
		&f.StoragePath,
		&f.CreatedAt,
	)
	if err != nil {
		return nil, err
	}

	if mimeType != nil {
		f.MimeType = *mimeType
	}

	return &f, nil
}

func nullString(s string) *string {
	if s == "" {
		return nil
	}

	return &s
}
