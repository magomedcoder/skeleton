package logger

import "testing"

func TestParseLevel(t *testing.T) {
	tests := []struct {
		s    string
		want int
	}{
		{"debug", LevelDebug},
		{"DEBUG", LevelDebug},
		{"verbose", LevelVerbose},
		{"v", LevelVerbose},
		{"info", LevelInfo},
		{"i", LevelInfo},
		{"warn", LevelWarning},
		{"warning", LevelWarning},
		{"w", LevelWarning},
		{"error", LevelError},
		{"e", LevelError},
		{"off", LevelOff},
		{"none", LevelOff},
		{"", LevelOff},
		{"unknown", LevelInfo},
	}
	for _, tt := range tests {
		got := ParseLevel(tt.s)
		if got != tt.want {
			t.Errorf("ParseLevel(%q) = %v, ожидалось %v", tt.s, got, tt.want)
		}
	}
}

func TestNew(t *testing.T) {
	l := New(LevelInfo, false)
	if l == nil {
		t.Fatal("New не должен возвращать nil")
	}
}
