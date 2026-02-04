package config

import "time"

type LogConfig struct {
	Level string
}

type AttachmentsConfig struct {
	SaveDir string
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

type Config struct {
	Server         ServerConfig
	Database       DatabaseConfig
	JWT            JWTConfig
	Runners        RunnersConfig
	Attachments    AttachmentsConfig
	Log            LogConfig
	MinClientBuild int32
	logLevel       string
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
		Attachments: AttachmentsConfig{
			// пусто = не сохранять
			SaveDir: "./uploads",
		},
		Log: LogConfig{
			// "debug", "verbose", "info", "warn", "error", "off" (по умолчанию "info")
			Level: "debug",
		},
		MinClientBuild: 1,
		logLevel:       "info",
	}

	return config, nil
}
