package usecase

import (
	"context"
	"errors"
	"io"
	"testing"

	"github.com/magomedcoder/legion/internal/config"
	"github.com/magomedcoder/legion/pkg/minio"
	minioapi "github.com/minio/minio-go/v7"
)

type mockMinio struct {
	write func(bucketName, objectName string, stream []byte) error
}

func (m *mockMinio) EnsureBucket(ctx context.Context, bucketName string) error {
	return nil
}

func (m *mockMinio) Stat(bucketName, objectName string) (*minio.FileStatInfo, error) {
	return nil, nil
}

func (m *mockMinio) Write(bucketName, objectName string, stream []byte) error {
	if m.write != nil {
		return m.write(bucketName, objectName, stream)
	}

	return nil
}

func (m *mockMinio) Copy(bucketName, srcObjectName, objectName string) error {
	return nil
}

func (m *mockMinio) CopyObject(srcBucketName, srcObjectName, dstBucketName, dstObjectName string) error {
	return nil
}

func (m *mockMinio) Delete(bucketName, objectName string) error {
	return nil
}

func (m *mockMinio) GetObject(bucketName, objectName string) (*minioapi.Object, error) {
	return nil, nil
}

func (m *mockMinio) InitiateMultipartUpload(bucketName, objectName string) (string, error) {
	return "", nil
}

func (m *mockMinio) PutObjectPart(bucketName, objectName string, uploadID string, index int, data io.Reader, size int64) (minio.ObjectPart, error) {
	return minio.ObjectPart{}, nil
}

func (m *mockMinio) CompleteMultipartUpload(bucketName, objectName, uploadID string, parts []minio.ObjectPart) error {
	return nil
}

func (m *mockMinio) AbortMultipartUpload(bucketName, objectName, uploadID string) error {
	return nil
}

var _ minio.IMinio = (*mockMinio)(nil)

func TestStorageUseCase_SaveAttachment_minioNotConfigured(t *testing.T) {
	uc := NewStorageUseCase(&config.Config{
		Minio: nil,
	}, &mockMinio{})
	ctx := context.Background()

	_, err := uc.SaveAttachment(ctx, "project", "proj-1", "file.txt", []byte("data"))
	if err == nil {
		t.Fatal("ожидалась ошибка при ненастроенном хранилище")
	}

	if err.Error() != "хранилище вложений не настроено" {
		t.Errorf("ошибка = %v", err)
	}
}

func TestStorageUseCase_SaveAttachment_bucketEmpty(t *testing.T) {
	uc := NewStorageUseCase(&config.Config{
		Minio: &config.Minio{
			Bucket: "",
		},
	}, &mockMinio{})
	ctx := context.Background()

	_, err := uc.SaveAttachment(ctx, "project", "proj-1", "file.txt", []byte("data"))
	if err == nil {
		t.Fatal("ожидалась ошибка при пустом bucket")
	}

	if err.Error() != "хранилище вложений не настроено" {
		t.Errorf("ошибка = %v", err)
	}
}

func TestStorageUseCase_SaveAttachment_success(t *testing.T) {
	var gotBucket, gotKey string
	var gotContent []byte
	m := &mockMinio{
		write: func(bucketName, objectName string, stream []byte) error {
			gotBucket = bucketName
			gotKey = objectName
			gotContent = append([]byte(nil), stream...)
			return nil
		},
	}
	conf := &config.Config{
		Minio: &config.Minio{Bucket: "legion"},
	}
	uc := NewStorageUseCase(conf, m)
	ctx := context.Background()

	content := []byte("hello")
	file, err := uc.SaveAttachment(ctx, "project", "proj-123", "doc.txt", content)
	if err != nil {
		t.Fatalf("SaveAttachment: %v", err)
	}

	if file == nil {
		t.Fatal("file не должен быть nil")
	}

	if file.Filename != "doc.txt" {
		t.Errorf("Filename = %s", file.Filename)
	}

	if file.Size != int64(len(content)) {
		t.Errorf("Size = %d", file.Size)
	}

	if file.Id == "" {
		t.Error("Id должен быть задан")
	}

	if gotBucket != "legion" {
		t.Errorf("bucket = %s", gotBucket)
	}

	if gotKey != file.StoragePath {
		t.Errorf("objectKey передан в Write не совпадает с file.StoragePath: %s", gotKey)
	}

	prefix := "attachments/project/proj-123/"
	if len(gotKey) < len(prefix) || gotKey[:len(prefix)] != prefix {
		t.Errorf("objectKey должен начинаться с %q, получено %q", prefix, gotKey)
	}

	if string(gotContent) != string(content) {
		t.Errorf("content в Write не совпадает: %q", gotContent)
	}
}

func TestStorageUseCase_SaveAttachment_writeError(t *testing.T) {
	m := &mockMinio{
		write: func(_, _ string, _ []byte) error {
			return errors.New("write failed")
		},
	}
	conf := &config.Config{
		Minio: &config.Minio{
			Bucket: "legion",
		},
	}
	uc := NewStorageUseCase(conf, m)
	ctx := context.Background()

	_, err := uc.SaveAttachment(ctx, "project", "proj-1", "file.txt", []byte("data"))
	if err == nil {
		t.Fatal("ожидалась ошибка от Write")
	}
}

func TestStorageUseCase_SaveAttachment_fileNameWithPath(t *testing.T) {
	var gotKey string
	m := &mockMinio{
		write: func(_, objectName string, _ []byte) error {
			gotKey = objectName
			return nil
		},
	}
	conf := &config.Config{
		Minio: &config.Minio{
			Bucket: "b",
		},
	}
	uc := NewStorageUseCase(conf, m)
	ctx := context.Background()

	file, err := uc.SaveAttachment(ctx, "task", "t-1", "dir/sub/file.txt", []byte("x"))
	if err != nil {
		t.Fatalf("SaveAttachment: %v", err)
	}

	if file.Filename != "file.txt" {
		t.Errorf("Filename должен быть base name: %s", file.Filename)
	}

	if len(gotKey) > 0 && gotKey[len(gotKey)-len("file.txt"):] != "file.txt" {
		t.Errorf("objectKey должен заканчиваться на file.txt: %s", gotKey)
	}
}

func TestStorageUseCase_SaveAttachment_emptyFileName(t *testing.T) {
	m := &mockMinio{
		write: func(_, _ string, _ []byte) error {
			return nil
		},
	}
	conf := &config.Config{
		Minio: &config.Minio{
			Bucket: "b",
		},
	}
	uc := NewStorageUseCase(conf, m)
	ctx := context.Background()

	file, err := uc.SaveAttachment(ctx, "project", "p-1", "", []byte("x"))
	if err != nil {
		t.Fatalf("SaveAttachment: %v", err)
	}

	if file.Filename != "attachment" {
		t.Errorf("при пустом имени ожидался Filename=attachment, получено %s", file.Filename)
	}
}

func TestStorageUseCase_SaveAttachment_dotFileName(t *testing.T) {
	m := &mockMinio{
		write: func(_, _ string, _ []byte) error {
			return nil
		},
	}
	conf := &config.Config{
		Minio: &config.Minio{
			Bucket: "b",
		},
	}
	uc := NewStorageUseCase(conf, m)
	ctx := context.Background()

	file, err := uc.SaveAttachment(ctx, "project", "p-1", ".", []byte("x"))
	if err != nil {
		t.Fatalf("SaveAttachment: %v", err)
	}

	if file.Filename != "attachment" {
		t.Errorf("при имени \".\" ожидался Filename=attachment, получено %s", file.Filename)
	}
}
