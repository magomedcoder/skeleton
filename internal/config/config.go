package config

import (
	"fmt"
	"os"
	"time"

	"github.com/magomedcoder/legion/pkg/encrypt"
	"github.com/magomedcoder/legion/pkg/strutil"
	"github.com/redis/go-redis/v9"
	"gopkg.in/yaml.v3"
)

type Duration struct {
	time.Duration
}

func (d *Duration) UnmarshalYAML(unmarshal func(interface{}) error) error {
	var s string
	if err := unmarshal(&s); err != nil {
		return err
	}

	dur, err := time.ParseDuration(s)
	if err != nil {
		return fmt.Errorf("неверный формат длительности: %w", err)
	}

	d.Duration = dur

	return nil
}

type LogConfig struct {
	Level string `yaml:"level"`
}

type AttachmentsConfig struct {
	SaveDir string `yaml:"save_dir"`
}

type RunnersConfig struct {
	Addresses         []string `yaml:"addresses"`
	RegistrationToken string   `yaml:"registration_token"`
}

type ServerConfig struct {
	Port string `yaml:"port"`
	Host string `yaml:"host"`
}

type DatabaseConfig struct {
	DSN string `yaml:"dsn"`
}

type JWTConfig struct {
	AccessSecret  string   `yaml:"access_secret"`
	RefreshSecret string   `yaml:"refresh_secret"`
	AccessTTL     Duration `yaml:"access_ttl"`
	RefreshTTL    Duration `yaml:"refresh_ttl"`
}

type Config struct {
	Server         ServerConfig      `yaml:"server"`
	Database       DatabaseConfig    `yaml:"database"`
	Redis          *Redis            `yaml:"redis"`
	JWT            JWTConfig         `yaml:"jwt"`
	Runners        RunnersConfig     `yaml:"runners"`
	Attachments    AttachmentsConfig `yaml:"attachments"`
	Log            LogConfig         `yaml:"log"`
	MinClientBuild int32
	sid            string
}

type Redis struct {
	Host     string `yaml:"host"`
	Port     int    `yaml:"port"`
	Auth     string `yaml:"auth"`
	Database int    `yaml:"database"`
}

func (r *Redis) Options() *redis.Options {
	return &redis.Options{
		Addr:        fmt.Sprintf("%s:%d", r.Host, r.Port),
		Password:    r.Auth,
		DB:          r.Database,
		ReadTimeout: -1,
	}
}

func Load() (*Config, error) {
	config := &Config{
		MinClientBuild: 1,
	}

	configPath := os.Getenv("LEGION_CONFIG")
	if configPath == "" {
		configPath = "./configs/config.yaml"
	}

	if _, err := os.Stat(configPath); err == nil {
		data, err := os.ReadFile(configPath)
		if err != nil {
			return nil, fmt.Errorf("ошибка чтения конфигурационного файла %s: %w", configPath, err)
		}

		if err := yaml.Unmarshal(data, config); err != nil {
			return nil, fmt.Errorf("ошибка парсинга конфигурационного файла %s: %w", configPath, err)
		}
	}

	config.sid = encrypt.Md5(fmt.Sprintf("%d%s", time.Now().UnixNano(), strutil.Random(6)))

	return config, nil
}

func (c *Config) ServerId() string {
	return c.sid
}
