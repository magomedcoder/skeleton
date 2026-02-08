package document

import "testing"

func TestExtractText_unknownExtension_returnsContent(t *testing.T) {
	content := []byte("произвольный текст")
	got, err := ExtractText("file.txt", content)
	if err != nil {
		t.Fatalf("ExtractText: %v", err)
	}

	if got != "произвольный текст" {
		t.Errorf("получено %q", got)
	}

	got, err = ExtractText("file.txt1", content)
	if err != nil {
		t.Fatalf("ExtractText: %v", err)
	}

	if got != "произвольный текст" {
		t.Errorf("получено %q", got)
	}
}

func TestExtractText_emptyContent(t *testing.T) {
	got, err := ExtractText("file.txt", nil)
	if err != nil {
		t.Fatalf("ExtractText: %v", err)
	}

	if got != "" {
		t.Errorf("ожидалась пустая строка, получено %q", got)
	}
}

func TestExtractText_CSV(t *testing.T) {
	content := []byte("a;b;c\n1;2;3")
	got, err := ExtractText("file.csv", content)
	if err != nil {
		t.Fatalf("ExtractText csv: %v", err)
	}

	if got != "a\tb\tc\n1\t2\t3" {
		t.Errorf("csv: получено %q", got)
	}
}

func TestExtractText_CSV_comma(t *testing.T) {
	content := []byte("a,b,c\n1,2,3")
	got, err := ExtractText("data.csv", content)
	if err != nil {
		t.Fatalf("ExtractText csv: %v", err)
	}

	if got != "a\tb\tc\n1\t2\t3" {
		t.Errorf("csv comma: получено %q", got)
	}
}
