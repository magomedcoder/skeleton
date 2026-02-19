package sliceutil

import (
	"testing"
)

func TestInclude(t *testing.T) {
	t.Run("string", func(t *testing.T) {
		arr := []string{"a", "b", "c"}
		if !Include("b", arr) {
			t.Error("Include(b) ожидалось true")
		}

		if Include("x", arr) {
			t.Error("Include(x) ожидалось false")
		}
	})
	t.Run("int", func(t *testing.T) {
		arr := []int{1, 2, 3}
		if !Include(2, arr) {
			t.Error("Include(2) ожидалось true")
		}

		if Include(0, arr) {
			t.Error("Include(0) ожидалось false")
		}
	})
}

func TestUnique(t *testing.T) {
	t.Run("string", func(t *testing.T) {
		got := Unique([]string{"a", "b", "a", "c", "b"})
		if len(got) != 3 {
			t.Errorf("Unique длина = %d, ожидалось 3", len(got))
		}
	})
	t.Run("int", func(t *testing.T) {
		got := Unique([]int64{1, 2, 1, 3})
		if len(got) != 3 {
			t.Errorf("Unique длина = %d, ожидалось 3", len(got))
		}
	})
}

func TestSum(t *testing.T) {
	if got := Sum([]int{1, 2, 3}); got != 6 {
		t.Errorf("Sum([]int{1,2,3}) = %d, ожидалось 6", got)
	}

	if got := Sum([]float64{1.5, 2.5}); got != 4.0 {
		t.Errorf("Sum([]float64{1.5, 2.5}) = %v, ожидалось 4", got)
	}

	if got := Sum([]int{}); got != 0 {
		t.Errorf("Sum([]int{}) = %d, ожидалось 0", got)
	}
}

func TestToMap(t *testing.T) {
	arr := []string{"a", "bb", "ccc"}
	got := ToMap(arr, func(s string) int { return len(s) })
	if got[1] != "a" || got[2] != "bb" || got[3] != "ccc" {
		t.Errorf("ToMap = %v", got)
	}
}

func TestParseIds(t *testing.T) {
	tests := []struct {
		in   string
		want []int
	}{
		{"", []int{}},
		{"1,2,3", []int{1, 2, 3}},
		{"1,abc,3", []int{1, 3}},
	}
	for _, tt := range tests {
		got := ParseIds(tt.in)
		if len(got) != len(tt.want) {
			t.Errorf("ParseIds(%q) = %v, ожидалось %v", tt.in, got, tt.want)
			continue
		}

		for i := range got {
			if got[i] != tt.want[i] {
				t.Errorf("ParseIds(%q)[%d] = %d, ожидалось %d", tt.in, i, got[i], tt.want[i])
			}
		}
	}
}

func TestParseIdsToInt64(t *testing.T) {
	got := ParseIdsToInt64("1,2,3")
	if len(got) != 3 || got[0] != 1 || got[1] != 2 || got[2] != 3 {
		t.Errorf("ParseIdsToInt64 = %v", got)
	}

	got = ParseIdsToInt64("")
	if len(got) != 0 {
		t.Errorf("ParseIdsToInt64(\"\") = %v", got)
	}
}

func TestToIds(t *testing.T) {
	got := ToIds([]int{1, 2, 3})
	if got != "1,2,3" {
		t.Errorf("ToIds = %q, ожидалось \"1,2,3\"", got)
	}

	got = ToIds([]int64{10, 20})
	if got != "10,20" {
		t.Errorf("ToIds int64 = %q", got)
	}
}
