package provider

import (
	"testing"

	"github.com/magomedcoder/skeleton/internal/runner/config"
)

func TestNewTextProvider_ollama(t *testing.T) {
	cfg := &config.Config{
		Engine: config.EngineOllama,
		Ollama: config.Ollama{
			BaseURL: "http://localhost:11434",
		},
	}

	tp, err := NewTextProvider(cfg)
	if err != nil {
		t.Fatalf("NewTextProvider(ollama): %v", err)
	}

	if tp == nil {
		t.Fatal("ожидался непустой провайдер")
	}
}

func TestNewTextProvider_llama_emptyPath(t *testing.T) {
	cfg := &config.Config{
		Engine: config.EngineLlama,
		Llama: config.Llama{
			ModelPath: "",
		},
	}

	_, err := NewTextProvider(cfg)
	if err == nil {
		t.Fatal("ожидалась ошибка при пустом model_path")
	}
}

func TestNewTextProvider_llama_withPath(t *testing.T) {
	cfg := &config.Config{
		Engine: config.EngineLlama,
		Llama: config.Llama{
			ModelPath: "/models",
		},
	}
	tp, err := NewTextProvider(cfg)
	if err != nil {
		t.Fatalf("NewTextProvider(llama): %v", err)
	}

	if tp == nil {
		t.Fatal("ожидался непустой провайдер")
	}
}

func TestNewTextProvider_unknownEngine(t *testing.T) {
	cfg := &config.Config{
		Engine: "unknown",
	}
	_, err := NewTextProvider(cfg)
	if err == nil {
		t.Fatal("ожидалась ошибка для неизвестного движка")
	}
}
