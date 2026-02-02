//go:build !nvidia

package gpu

type stubCollector struct{}

func NewCollector() Collector {
	return &stubCollector{}
}

func (s *stubCollector) Collect() []Info {
	return nil
}
