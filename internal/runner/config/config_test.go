package config

import "testing"

func TestLoad(t *testing.T) {
	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load: %v", err)
	}

	if cfg == nil {
		t.Fatal("конфиг не должен быть nil")
	}

	if cfg.CoreAddr == "" || cfg.ListenAddr == "" {
		t.Error("адреса должны быть заданы")
	}

	if cfg.Engine != EngineOllama && cfg.Engine != EngineLlama {
		t.Errorf("Engine: %q", cfg.Engine)
	}

	if cfg.Ollama.BaseURL == "" {
		t.Error("Ollama.BaseURL должен быть задан")
	}
}

func TestEngineConstants(t *testing.T) {
	if EngineOllama == "" || EngineLlama == "" {
		t.Error("константы движков не должны быть пустыми")
	}
}
