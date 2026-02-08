package postgres

import (
	"time"

	"github.com/magomedcoder/skeleton/internal/domain"
)

type fileModel struct {
	Id          string    `gorm:"column:id;primaryKey;type:uuid"`
	Filename    string    `gorm:"column:filename;size:255;not null"`
	MimeType    *string   `gorm:"column:mime_type;size:100"`
	Size        int64     `gorm:"column:size;not null;default:0"`
	StoragePath string    `gorm:"column:storage_path;type:text;not null"`
	CreatedAt   time.Time `gorm:"column:created_at;not null"`
}

func (fileModel) TableName() string {
	return "files"
}

func fileModelToDomain(m *fileModel) *domain.File {
	if m == nil {
		return nil
	}

	mimeType := ""
	if m.MimeType != nil {
		mimeType = *m.MimeType
	}

	return &domain.File{
		Id:          m.Id,
		Filename:    m.Filename,
		MimeType:    mimeType,
		Size:        m.Size,
		StoragePath: m.StoragePath,
		CreatedAt:   m.CreatedAt,
	}
}

func fileDomainToModel(f *domain.File) *fileModel {
	if f == nil {
		return nil
	}

	var mimeType *string
	if f.MimeType != "" {
		mimeType = &f.MimeType
	}

	return &fileModel{
		Id:          f.Id,
		Filename:    f.Filename,
		MimeType:    mimeType,
		Size:        f.Size,
		StoragePath: f.StoragePath,
		CreatedAt:   f.CreatedAt,
	}
}
