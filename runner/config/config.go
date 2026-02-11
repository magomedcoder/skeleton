package config

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

const (
	EngineOllama = "ollama"
	EngineLlama  = "llama"
)

type Ollama struct {
	BaseURL string `yaml:"base_url"`
}

type Llama struct {
	ModelPath string `yaml:"model_path"`
}

type LogConfig struct {
	Level string `yaml:"level"`
}

type Config struct {
	CoreAddr   string    `yaml:"core_addr"`
	ListenAddr string    `yaml:"listen_addr"`
	Log        LogConfig `yaml:"log"`
	Engine     string    `yaml:"engine"`
	Ollama     Ollama    `yaml:"ollama"`
	Llama      Llama     `yaml:"llama"`
}

func Load() (*Config, error) {
	c := &Config{}

	configPath := os.Getenv("LEGION_RUNNER_CONFIG")
	if configPath == "" {
		configPath = "./configs/runner-config.yaml"
	}

	if _, err := os.Stat(configPath); err == nil {
		data, err := os.ReadFile(configPath)
		if err != nil {
			return nil, fmt.Errorf("ошибка чтения конфигурационного файла %s: %w", configPath, err)
		}

		if err := yaml.Unmarshal(data, c); err != nil {
			return nil, fmt.Errorf("ошибка парсинга конфигурационного файла %s: %w", configPath, err)
		}
	}

	return c, nil
}
