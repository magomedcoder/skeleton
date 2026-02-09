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

	if cfg.Database.DSN == "" {
		t.Error("DSN базы данных должен быть задан")
	}

	if cfg.JWT.AccessSecret == "" || cfg.JWT.RefreshSecret == "" {
		t.Error("секреты JWT должны быть заданы")
	}

	if cfg.MinClientBuild < 0 {
		t.Error("MinClientBuild должен быть неотрицательным")
	}
}
