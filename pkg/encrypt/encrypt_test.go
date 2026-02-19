package encrypt

import (
	"testing"
)

func TestMd5(t *testing.T) {
	tests := []struct {
		name string
		in   string
		want string
	}{
		{"пустая строка", "", "d41d8cd98f00b204e9800998ecf8427e"},
		{"hello", "hello", "5d41402abc4b2a76b9719d911017c592"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := Md5(tt.in)
			if got != tt.want {
				t.Errorf("Md5(%q) = %q, ожидалось %q", tt.in, got, tt.want)
			}
		})
	}
	t.Run("русский текст — 32 hex символа", func(t *testing.T) {
		got := Md5("привет")
		if len(got) != 32 {
			t.Errorf("Md5() длина = %d, ожидалось 32", len(got))
		}

		for _, c := range got {
			if (c < '0' || c > '9') && (c < 'a' || c > 'f') {
				t.Errorf("Md5 должен быть hex: %q", got)
				break
			}
		}
	})
}

func TestMd5_deterministic(t *testing.T) {
	a, b := Md5("same"), Md5("same")
	if a != b {
		t.Errorf("Md5 должен быть детерминированным: %q != %q", a, b)
	}
}
