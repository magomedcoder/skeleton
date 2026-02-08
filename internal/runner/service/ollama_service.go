package service

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"github.com/magomedcoder/skeleton/internal/domain"
	"github.com/magomedcoder/skeleton/internal/runner/config"
	"io"
	"net/http"
	"time"
)

type OllamaService struct {
	baseURL string
	client  *http.Client
}

func NewOllamaService(conf config.Ollama) *OllamaService {
	return &OllamaService{
		baseURL: conf.BaseURL,
		client: &http.Client{
			Timeout: 150 * time.Second,
		},
	}
}

func (o *OllamaService) CheckConnection(ctx context.Context) (bool, error) {
	req, err := http.NewRequestWithContext(ctx, "GET", o.baseURL+"/api/tags", nil)
	if err != nil {
		return false, fmt.Errorf("не удалось создать запрос: %w", err)
	}

	resp, err := o.client.Do(req)
	if err != nil {
		return false, fmt.Errorf("ошибка подключения: %w", err)
	}
	defer resp.Body.Close()

	return resp.StatusCode == http.StatusOK, nil
}

type tagsResponse struct {
	Models []struct {
		Name string `json:"name"`
	} `json:"models"`
}

func (o *OllamaService) GetModels(ctx context.Context) ([]string, error) {
	req, err := http.NewRequestWithContext(ctx, "GET", o.baseURL+"/api/tags", nil)
	if err != nil {
		return nil, fmt.Errorf("не удалось создать запрос: %w", err)
	}

	resp, err := o.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("ошибка подключения: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("ollama вернул статус: %d", resp.StatusCode)
	}

	var data tagsResponse
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, fmt.Errorf("не удалось прочитать список моделей: %w", err)
	}

	names := make([]string, 0, len(data.Models))
	for _, m := range data.Models {
		if m.Name != "" {
			names = append(names, m.Name)
		}
	}
	return names, nil
}

func (o *OllamaService) SendMessage(ctx context.Context, model string, messages []*domain.AIChatMessage) (chan string, error) {
	ollamaMessages := make([]map[string]interface{}, len(messages))
	for i, msg := range messages {
		ollamaMessages[i] = msg.AIToMap()
	}

	requestBody := map[string]interface{}{
		"model":    model,
		"messages": ollamaMessages,
		"stream":   true,
	}

	jsonBody, err := json.Marshal(requestBody)
	if err != nil {
		return nil, fmt.Errorf("не удалось сериализовать запрос: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", o.baseURL+"/api/chat", bytes.NewBuffer(jsonBody))
	if err != nil {
		return nil, fmt.Errorf("не удалось создать запрос: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := o.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("не удалось отправить запрос: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		resp.Body.Close()
		return nil, fmt.Errorf("ollama вернул статус: %d", resp.StatusCode)
	}

	output := make(chan string, 100)

	go func() {
		defer resp.Body.Close()
		defer close(output)

		scanner := bufio.NewScanner(resp.Body)
		for scanner.Scan() {
			line := scanner.Text()
			if line == "" {
				continue
			}

			var data map[string]interface{}
			if err := json.Unmarshal([]byte(line), &data); err != nil {
				continue
			}

			if message, ok := data["message"].(map[string]interface{}); ok {
				if content, ok := message["content"].(string); ok && content != "" {
					select {
					case <-ctx.Done():
						return
					case output <- content:
					}
				}
			}

			if done, ok := data["done"].(bool); ok && done {
				break
			}
		}

		if err := scanner.Err(); err != nil && err != io.EOF {
		}
	}()

	return output, nil
}
