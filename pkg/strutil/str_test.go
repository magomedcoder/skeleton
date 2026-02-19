package strutil

import (
	"regexp"
	"testing"
)

func TestRandom(t *testing.T) {
	for _, length := range []int{0, 1, 10, 100} {
		got := Random(length)
		if len(got) != length {
			t.Errorf("Random(%d) длина = %d", length, len(got))
		}

		allowed := regexp.MustCompile(`^[0-9a-z]*$`)
		if !allowed.MatchString(got) {
			t.Errorf("Random(%d) = %q содержит недопустимые символы", length, got)
		}
	}
}

func TestNewMsgId(t *testing.T) {
	got := NewMsgId()
	if len(got) != 32 {
		t.Errorf("NewMsgId() длина = %d, ожидалось 32 (UUID без дефисов)", len(got))
	}

	noHyphens := regexp.MustCompile(`^[0-9a-f]{32}$`)
	if !noHyphens.MatchString(got) {
		t.Errorf("NewMsgId() = %q должен быть hex без дефисов", got)
	}
}
