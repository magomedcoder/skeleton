package config

const (
	EngineOllama = "ollama"
	EngineLlama  = "llama"
)

type Ollama struct {
	BaseURL string
}

type Llama struct {
	ModelPath string
}

type LogConfig struct {
	Level string
}

type Config struct {
	CoreAddr   string
	ListenAddr string
	Log        LogConfig
	Engine     string
	Ollama     Ollama
	Llama      Llama
}

func Load() (*Config, error) {
	c := &Config{
		CoreAddr:   "127.0.0.1:50051",
		ListenAddr: "127.0.0.1:50052",
		Log: LogConfig{
			Level: "debug",
		},
		Ollama: Ollama{
			BaseURL: "http://127.0.0.1:11434",
		},
	}

	// EngineOllama или EngineLlama
	c.Engine = EngineOllama
	return c, nil
}
