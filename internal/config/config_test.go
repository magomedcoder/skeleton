package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLoad(t *testing.T) {
	wd, err := os.Getwd()
	if err != nil {
		t.Fatalf("Getwd: %v", err)
	}

	projectRoot := filepath.Join(wd, "..", "..")
	configPath := filepath.Join(projectRoot, "configs", "config.yaml")
	os.Setenv("LEGION_CONFIG", configPath)
	defer os.Unsetenv("LEGION_CONFIG")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load: %v", err)
	}

	if cfg == nil {
		t.Fatal("конфиг не должен быть nil")
	}

	if cfg.Server.Port == "" || cfg.Server.Host == "" {
		t.Error("конфиг сервера должен быть задан")
	}

	if cfg.Postgres.Host == "" || cfg.Postgres.Database == "" {
		t.Error("postgres: host и database должны быть заданы")
	}

	if cfg.JWT.AccessSecret == "" || cfg.JWT.RefreshSecret == "" {
		t.Error("секреты JWT должны быть заданы")
	}

	if cfg.MinClientBuild < 0 {
		t.Error("MinClientBuild должен быть неотрицательным")
	}

	if cfg.Minio != nil && cfg.Minio.Bucket == "" {
		t.Error("при включённом minio bucket должен быть задан")
	}
}

func TestNewMinioClient_nilMinio(t *testing.T) {
	got := NewMinioClient(&Config{Minio: nil})
	if got != nil {
		t.Errorf("NewMinioClient при Minio == nil должен возвращать nil, получено %v", got)
	}
}

func TestNewMinioClient_emptyMinio(t *testing.T) {
	got := NewMinioClient(&Config{})
	if got != nil {
		t.Errorf("NewMinioClient при пустом Config должен возвращать nil, получено %v", got)
	}
}
