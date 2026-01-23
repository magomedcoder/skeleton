package service

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/magomedcoder/legion/internal/domain"
)

type OllamaService struct {
	baseURL string
	model   string
	client  *http.Client
}

func NewOllamaService(baseURL, model string) *OllamaService {
	return &OllamaService{
		baseURL: baseURL,
		model:   model,
		client: &http.Client{
			Timeout: 150 * time.Second,
		},
	}
}

func (c *OllamaService) CheckConnection(ctx context.Context) (bool, error) {
	req, err := http.NewRequestWithContext(ctx, "GET", c.baseURL+"/api/tags", nil)
	if err != nil {
		return false, fmt.Errorf("не удалось создать запрос: %w", err)
	}

	resp, err := c.client.Do(req)
	if err != nil {
		return false, fmt.Errorf("ошибка подключения: %w", err)
	}
	defer resp.Body.Close()

	return resp.StatusCode == http.StatusOK, nil
}

func (c *OllamaService) SendMessage(ctx context.Context, messages []*domain.Message) (chan string, error) {
	ollamaMessages := make([]map[string]interface{}, len(messages))
	for i, msg := range messages {
		ollamaMessages[i] = msg.ToMap()
	}

	requestBody := map[string]interface{}{
		"model":    c.model,
		"messages": ollamaMessages,
		"stream":   true,
	}

	jsonBody, err := json.Marshal(requestBody)
	if err != nil {
		return nil, fmt.Errorf("не удалось сериализовать запрос: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", c.baseURL+"/api/chat", bytes.NewBuffer(jsonBody))
	if err != nil {
		return nil, fmt.Errorf("не удалось создать запрос: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.client.Do(req)
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
