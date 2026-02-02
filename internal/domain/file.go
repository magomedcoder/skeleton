package domain

import (
	"time"

	"github.com/google/uuid"
)

type File struct {
	Id          string
	Filename    string
	MimeType    string
	Size        int64
	StoragePath string
	CreatedAt   time.Time
}

func NewFile(filename, mimeType string, size int64, storagePath string) *File {
	return &File{
		Id:          uuid.New().String(),
		Filename:    filename,
		MimeType:    mimeType,
		Size:        size,
		StoragePath: storagePath,
		CreatedAt:   time.Now(),
	}
}
