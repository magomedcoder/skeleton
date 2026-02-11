package load

import (
	"context"
	"fmt"
	"testing"
	"time"
)

const (
	loadTarget   = "127.0.0.1:50051"
	loadDuration = 5 * time.Second // Длительность нагрузочного теста
	loadWorkers  = 4               // Число параллельных воркеров
	loadUser     = "legion"
	loadPass     = "password"
)

func TestLoad(t *testing.T) {
	cfg := Config{
		Target:   loadTarget,
		Duration: loadDuration,
		Workers:  loadWorkers,
		Username: loadUser,
		Password: loadPass,
	}

	ctx, cancel := context.WithTimeout(context.Background(), cfg.Duration+10*time.Second)
	defer cancel()

	report, err := Run(ctx, cfg)
	if err != nil {
		t.Fatalf("нагрузочный тест: %v", err)
	}

	t.Logf("Нагрузочный тест завершён:")
	t.Logf("  Запросов: %d", report.Total)
	t.Logf("  Ошибок: %d", report.Errors)
	t.Logf("  RPS: %.1f", report.RPS)
	t.Logf("  Задержка: avg=%.2f ms, p50=%.2f ms, p95=%.2f ms, p99=%.2f ms", report.AvgMs, report.P50Ms, report.P95Ms, report.P99Ms)

	if report.Total == 0 {
		t.Fatal("не выполнено ни одного запроса")
	}

	errRate := float64(report.Errors) / float64(report.Total) * 100
	if errRate > 1 {
		t.Errorf("доля ошибок %.2f%% превышает 1%%", errRate)
	}
}

// TestLoadReport выводит отчёт в stdout
func TestLoadReport(t *testing.T) {
	cfg := Config{
		Target:   loadTarget,
		Duration: loadDuration,
		Workers:  loadWorkers,
		Username: loadUser,
		Password: loadPass,
	}

	ctx, cancel := context.WithTimeout(context.Background(), cfg.Duration+15*time.Second)
	defer cancel()

	report, err := Run(ctx, cfg)
	if err != nil {
		t.Fatalf("Run: %v", err)
	}

	// - Длительность: общее время выполнения теста
	// - Запросов: общее количество выполненных запросов
	// - Ошибок: количество запросов, завершившихся с ошибкой
	// - RPS (Requests Per Second): среднее количество запросов в секунду
	// - Задержка avg: средняя задержка ответа в миллисекундах
	// - Задержка p50/p95/p99: перцентили задержки
	//   p50 (медиана) - у половины запросов задержка была не больше этого значения
	//   p95 - у 95% запросов задержка не больше этого значения; 5% - медленнее
	//   p99 - у 99% запросов задержка не больше этого значения; 1% - медленнее (хвост распределения)
	fmt.Println("Нагрузочный тест")
	fmt.Printf("  Длительность: %v\n", report.Duration.Round(time.Millisecond))
	fmt.Printf("  Запросов: %d\n", report.Total)
	fmt.Printf("  Ошибок: %d\n", report.Errors)
	fmt.Printf("  RPS: %.1f\n", report.RPS)
	fmt.Printf("  Задержка avg: %.2f ms\n", report.AvgMs)
	fmt.Printf("  Задержка p50: %.2f ms\n", report.P50Ms)
	fmt.Printf("  Задержка p95: %.2f ms\n", report.P95Ms)
	fmt.Printf("  Задержка p99: %.2f ms\n", report.P99Ms)
}
