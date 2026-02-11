//go:build !nvidia

package gpu

import "testing"

func TestNewCollector_stub(t *testing.T) {
	c := NewCollector()
	if c == nil {
		t.Fatal("NewCollector не должен возвращать nil")
	}
}

func TestStubCollector_Collect(t *testing.T) {
	c := NewCollector()
	infos := c.Collect()
	if infos != nil {
		t.Errorf("stub Collect должен возвращать nil, получено %v", infos)
	}
}
