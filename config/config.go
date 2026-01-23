package config

import (
	"time"
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	JWT      JWTConfig
	Ollama   OllamaConfig
}

type ServerConfig struct {
	Port string
	Host string
}

type DatabaseConfig struct {
	DSN string
}

type JWTConfig struct {
	AccessSecret  string
	RefreshSecret string
	AccessTTL     time.Duration
	RefreshTTL    time.Duration
}

type OllamaConfig struct {
	BaseURL string
	Model   string
}

func Load() (*Config, error) {
	config := &Config{
		Server: ServerConfig{
			Port: "50051",
			Host: "0.0.0.0",
		},
		Database: DatabaseConfig{
			DSN: "postgres://postgres:postgres@127.0.0.1:5432/legion",
		},
		JWT: JWTConfig{
			AccessSecret:  "legion",
			RefreshSecret: "legion",
			AccessTTL:     15 * time.Minute,
			RefreshTTL:    7 * 24 * time.Hour,
		},
		Ollama: OllamaConfig{
			BaseURL: "http://localhost:11434",
			Model:   "llama3.2",
		},
	}

	return config, nil
}
