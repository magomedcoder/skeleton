package jsonutil

import (
	"strings"
	"testing"
)

func TestEncode(t *testing.T) {
	type T struct{ A int }
	got := Encode(T{A: 1})
	if len(got) == 0 {
		t.Error("Encode вернул пустую строку")
	}
	if !strings.Contains(got, "1") {
		t.Errorf("Encode должен содержать значение: %q", got)
	}
}

func TestMarshal(t *testing.T) {
	type T struct{ A int }
	got := Marshal(T{A: 1})
	if len(got) == 0 {
		t.Error("Marshal вернул пустой слайс")
	}
}

func TestDecode(t *testing.T) {
	type T struct{ A int }

	t.Run("string", func(t *testing.T) {
		var v T
		err := Decode(`{"A":42}`, &v)
		if err != nil {
			t.Fatalf("Decode: %v", err)
		}
		if v.A != 42 {
			t.Errorf("A = %d, ожидалось 42", v.A)
		}
	})
	t.Run("bytes", func(t *testing.T) {
		var v T
		err := Decode([]byte(`{"A":10}`), &v)
		if err != nil {
			t.Fatalf("Decode: %v", err)
		}
		if v.A != 10 {
			t.Errorf("A = %d, ожидалось 10", v.A)
		}
	})
	t.Run("unknown type", func(t *testing.T) {
		var v T
		err := Decode(123, &v)
		if err == nil {
			t.Fatal("ожидалась ошибка для неизвестного типа")
		}
		if err.Error() != "неизвестный тип" {
			t.Errorf("ошибка = %v", err)
		}
	})
}
