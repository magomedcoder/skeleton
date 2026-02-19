package minio

import (
	"context"
	"fmt"
	"io"
	"path"
	"strings"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

type IMinio interface {
	EnsureBucket(ctx context.Context, bucketName string) error

	Stat(bucketName string, objectName string) (*FileStatInfo, error)

	Write(bucketName string, objectName string, stream []byte) error

	Copy(bucketName string, srcObjectName, objectName string) error

	CopyObject(srcBucketName string, srcObjectName, dstBucketName string, dstObjectName string) error

	Delete(bucketName string, objectName string) error

	GetObject(bucketName string, objectName string) (*minio.Object, error)

	InitiateMultipartUpload(bucketName, objectName string) (string, error)

	PutObjectPart(bucketName, objectName string, uploadID string, index int, data io.Reader, size int64) (ObjectPart, error)

	CompleteMultipartUpload(bucketName, objectName, uploadID string, parts []ObjectPart) error

	AbortMultipartUpload(bucketName, objectName, uploadID string) error
}

var _ IMinio = (*Minio)(nil)

type Minio struct {
	Core   *minio.Core
	Config Config
}

type Config struct {
	Endpoint  string
	SSL       bool
	SecretId  string
	SecretKey string
}

func NewMinio(conf Config) *Minio {
	client, err := minio.NewCore(conf.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(conf.SecretId, conf.SecretKey, ""),
		Secure: conf.SSL,
	})

	if err != nil {
		panic(fmt.Sprintf("Не удалось инициализировать minio-клиент: %s", err))
	}

	return &Minio{
		Core:   client,
		Config: conf,
	}
}

func (m Minio) EnsureBucket(ctx context.Context, bucketName string) error {
	ok, err := m.Core.Client.BucketExists(ctx, bucketName)
	if err != nil {
		return fmt.Errorf("проверка бакета %s: %w", bucketName, err)
	}

	if ok {
		return nil
	}

	if err := m.Core.Client.MakeBucket(ctx, bucketName, minio.MakeBucketOptions{}); err != nil {
		return fmt.Errorf("создание бакета %s: %w", bucketName, err)
	}

	return nil
}

type FileStatInfo struct {
	Name        string
	Size        int64
	Ext         string
	MimeType    string
	LastModTime time.Time
}

func (m Minio) Stat(bucketName string, objectName string) (*FileStatInfo, error) {
	objInfo, err := m.Core.Client.StatObject(context.Background(), bucketName, objectName, minio.StatObjectOptions{})
	if err != nil {
		return nil, err
	}

	return &FileStatInfo{
		LastModTime: objInfo.LastModified,
		MimeType:    objInfo.ContentType,
		Name:        objInfo.Key,
		Size:        objInfo.Size,
		Ext:         path.Ext(objectName),
	}, nil
}

func (m Minio) Write(bucketName string, objectName string, stream []byte) error {
	_, err := m.Core.Client.PutObject(context.Background(), bucketName, objectName, strings.NewReader(string(stream)), int64(len(stream)), minio.PutObjectOptions{})
	return err
}

func (m Minio) Copy(bucketName string, srcObjectName, objectName string) error {
	return m.CopyObject(bucketName, srcObjectName, bucketName, objectName)
}

func (m Minio) CopyObject(srcBucketName string, srcObjectName, dstBucketName string, dstObjectName string) error {
	srcOpts := minio.CopySrcOptions{
		Bucket: srcBucketName,
		Object: srcObjectName,
	}

	dstOpts := minio.CopyDestOptions{
		Bucket: dstBucketName,
		Object: dstObjectName,
	}

	_, err := m.Core.Client.CopyObject(context.Background(), dstOpts, srcOpts)
	return err
}

func (m Minio) Delete(bucketName string, objectName string) error {
	return m.Core.Client.RemoveObject(context.Background(), bucketName, objectName, minio.RemoveObjectOptions{})
}

func (m Minio) GetObject(bucketName string, objectName string) (*minio.Object, error) {
	object, err := m.Core.Client.GetObject(context.Background(), bucketName, objectName, minio.GetObjectOptions{})
	if err != nil {
		return nil, err
	}

	return object, nil
}

func (m Minio) InitiateMultipartUpload(bucketName, objectName string) (string, error) {
	return m.Core.NewMultipartUpload(context.Background(), bucketName, objectName, minio.PutObjectOptions{})
}

type ObjectPart struct {
	PartNumber     int
	ETag           string
	PartObjectName string
}

func (m Minio) PutObjectPart(bucketName, objectName string, uploadID string, index int, data io.Reader, size int64) (ObjectPart, error) {
	part, err := m.Core.PutObjectPart(context.Background(), bucketName, objectName, uploadID, index, data, size, minio.PutObjectPartOptions{})
	if err != nil {
		return ObjectPart{}, err
	}

	return ObjectPart{
		PartNumber: part.PartNumber,
		ETag:       part.ETag,
	}, nil
}

func (m Minio) CompleteMultipartUpload(bucketName, objectName, uploadID string, parts []ObjectPart) error {
	completeParts := make([]minio.CompletePart, 0)

	for _, part := range parts {
		completeParts = append(completeParts, minio.CompletePart{
			PartNumber: part.PartNumber,
			ETag:       part.ETag,
		})
	}

	_, err := m.Core.CompleteMultipartUpload(context.Background(), bucketName, objectName, uploadID, completeParts, minio.PutObjectOptions{})
	return err
}

func (m Minio) AbortMultipartUpload(bucketName, objectName, uploadID string) error {
	return m.Core.AbortMultipartUpload(context.Background(), bucketName, objectName, uploadID)
}
