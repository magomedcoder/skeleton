package config

import (
	"time"
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	JWT      JWTConfig
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

func Load() (*Config, error) {

	config := &Config{
		Server: ServerConfig{
			Port: "50051",
			Host: "0.0.0.0",
		},
		Database: DatabaseConfig{
			DSN: "postgres://postgres:postgres@localhost:5432/assist?sslmode=disable",
		},
		JWT: JWTConfig{
			AccessSecret:  "assist",
			RefreshSecret: "assist",
			AccessTTL:     15 * time.Minute,
			RefreshTTL:    7 * 24 * time.Hour,
		},
	}

	return config, nil
}
