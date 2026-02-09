package load

import (
	"sort"
	"sync"
	"time"
)

type Stats struct {
	mu        sync.Mutex
	latencies []time.Duration
	errors    int
}

func NewStats() *Stats {
	return &Stats{
		latencies: make([]time.Duration, 0, 1024),
	}
}

// Record записывает один запрос (задержка и признак ошибки)
func (s *Stats) Record(latency time.Duration, err bool) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.latencies = append(s.latencies, latency)
	if err {
		s.errors++
	}
}

// Merge объединяет статистику из другого Stats (например из воркеров)
func (s *Stats) Merge(other *Stats) {
	other.mu.Lock()
	latencies := append([]time.Duration(nil), other.latencies...)
	errors := other.errors
	other.mu.Unlock()

	s.mu.Lock()
	defer s.mu.Unlock()

	s.latencies = append(s.latencies, latencies...)
	s.errors += errors
}

// Report возвращает количество запросов, ошибок, RPS, перцентили задержки
func (s *Stats) Report(duration time.Duration) Report {
	s.mu.Lock()
	defer s.mu.Unlock()

	n := len(s.latencies)
	if n == 0 {
		return Report{
			Total:  0,
			Errors: s.errors,
			RPS:    0,
		}
	}

	lat := make([]time.Duration, n)
	copy(lat, s.latencies)

	sort.Slice(lat, func(i, j int) bool { return lat[i] < lat[j] })

	sec := duration.Seconds()
	if sec <= 0 {
		sec = 1
	}

	return Report{
		Total:    n,
		Errors:   s.errors,
		RPS:      float64(n) / sec,
		AvgMs:    avgMs(lat),
		P50Ms:    percentileMs(lat, 0.5),
		P95Ms:    percentileMs(lat, 0.95),
		P99Ms:    percentileMs(lat, 0.99),
		Duration: duration,
	}
}

type Report struct {
	Total    int
	Errors   int
	RPS      float64
	AvgMs    float64
	P50Ms    float64
	P95Ms    float64
	P99Ms    float64
	Duration time.Duration
}

func avgMs(lat []time.Duration) float64 {
	if len(lat) == 0 {
		return 0
	}

	var sum time.Duration
	for _, d := range lat {
		sum += d
	}

	return float64(sum.Microseconds()) / 1000 / float64(len(lat))
}

func percentileMs(sorted []time.Duration, p float64) float64 {
	if len(sorted) == 0 {
		return 0
	}

	idx := int(p * float64(len(sorted)))
	if idx >= len(sorted) {
		idx = len(sorted) - 1
	}

	return float64(sorted[idx].Microseconds()) / 1000
}
