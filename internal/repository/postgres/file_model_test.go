package postgres

import (
	"testing"
	"time"

	"github.com/magomedcoder/skeleton/internal/domain"
)

func Test_fileModelToDomain(t *testing.T) {
	now := time.Now()

	t.Run("nil возвращает nil", func(t *testing.T) {
		if got := fileModelToDomain(nil); got != nil {
			t.Errorf("fileModelToDomain(nil) = %v, ожидалось nil", got)
		}
	})

	t.Run("с MimeType nil", func(t *testing.T) {
		m := &fileModel{
			Id:          "f1",
			Filename:    "a.txt",
			Size:        100,
			StoragePath: "/path",
			CreatedAt:   now,
		}
		got := fileModelToDomain(m)
		if got == nil || got.MimeType != "" {
			t.Errorf("fileModelToDomain: MimeType должен быть пустым при nil, получено %q", got.MimeType)
		}
	})

	t.Run("с MimeType задан", func(t *testing.T) {
		mt := "text/plain"
		m := &fileModel{
			Id:          "f2",
			Filename:    "b.txt",
			MimeType:    &mt,
			Size:        200,
			StoragePath: "/p",
			CreatedAt:   now,
		}
		got := fileModelToDomain(m)
		if got == nil || got.MimeType != "text/plain" {
			t.Errorf("fileModelToDomain: MimeType = %q, ожидалось text/plain", got.MimeType)
		}
	})
}

func Test_fileDomainToModel(t *testing.T) {
	now := time.Now()

	t.Run("nil возвращает nil", func(t *testing.T) {
		if got := fileDomainToModel(nil); got != nil {
			t.Errorf("fileDomainToModel(nil) = %v, ожидалось nil", got)
		}
	})

	t.Run("пустой MimeType -> nil в модели", func(t *testing.T) {
		f := &domain.File{
			Id:          "f1",
			Filename:    "a.txt",
			Size:        100,
			StoragePath: "/path",
			CreatedAt:   now,
		}
		got := fileDomainToModel(f)
		if got == nil || got.MimeType != nil {
			t.Errorf("fileDomainToModel: MimeType должен быть nil при пустой строке, получено %v", got.MimeType)
		}
	})

	t.Run("задан MimeType", func(t *testing.T) {
		f := &domain.File{
			Id:          "f2",
			Filename:    "b.txt",
			MimeType:    "text/plain",
			Size:        200,
			StoragePath: "/p",
			CreatedAt:   now,
		}
		got := fileDomainToModel(f)
		if got == nil || got.MimeType == nil || *got.MimeType != "text/plain" {
			t.Errorf("fileDomainToModel: %+v", got)
		}
	})
}
