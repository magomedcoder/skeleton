package config

import (
	"time"
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	JWT      JWTConfig
	Runners  RunnersConfig
}

type RunnersConfig struct {
	Addresses []string
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
			DSN: "postgres://postgres:postgres@127.0.0.1:5432/legion",
		},
		JWT: JWTConfig{
			AccessSecret:  "legion",
			RefreshSecret: "legion",
			AccessTTL:     15 * time.Minute,
			RefreshTTL:    7 * 24 * time.Hour,
		},
		Runners: RunnersConfig{
			// ["localhost:50052", "192.168.1.10:50052"]
			Addresses: []string{"127.0.0.1:50052"},
		},
	}

	return config, nil
}
