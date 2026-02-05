package document

import (
	"archive/zip"
	"bytes"
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/ledongthuc/pdf"
	"github.com/xuri/excelize/v2"
)

func ExtractText(filename string, content []byte) (string, error) {
	ext := strings.ToLower(filepath.Ext(filename))
	switch ext {
	case ".pdf":
		return extractPDF(content)
	case ".docx":
		return extractDOCX(content)
	case ".xlsx":
		return extractXLSX(content)
	case ".csv":
		return extractCSV(content)
	default:
		return string(content), nil
	}
}

func extractPDF(content []byte) (string, error) {
	tmp, err := os.CreateTemp("", "skeleton-pdf-*.pdf")
	if err != nil {
		return "", fmt.Errorf("создание временного файла: %w", err)
	}
	defer os.Remove(tmp.Name())
	defer tmp.Close()

	if _, err := tmp.Write(content); err != nil {
		return "", fmt.Errorf("запись во временный файл: %w", err)
	}

	if err := tmp.Sync(); err != nil {
		return "", fmt.Errorf("sync временного файла: %w", err)
	}

	tmp.Close()

	f, r, err := pdf.Open(tmp.Name())
	if err != nil {
		return "", fmt.Errorf("открытие PDF: %w", err)
	}
	defer f.Close()

	reader, err := r.GetPlainText()
	if err != nil {
		return "", fmt.Errorf("извлечение текста из PDF: %w", err)
	}

	data, err := io.ReadAll(reader)
	if err != nil {
		return "", fmt.Errorf("чтение текста PDF: %w", err)
	}

	return string(data), nil
}

func extractDOCX(content []byte) (string, error) {
	zr, err := zip.NewReader(bytes.NewReader(content), int64(len(content)))
	if err != nil {
		return "", fmt.Errorf("открытие DOCX (zip): %w", err)
	}

	var docXML io.ReadCloser
	for _, f := range zr.File {
		if f.Name == "word/document.xml" {
			docXML, err = f.Open()
			if err != nil {
				return "", fmt.Errorf("открытие word/document.xml: %w", err)
			}
			break
		}
	}
	if docXML == nil {
		return "", fmt.Errorf("word/document.xml не найден в DOCX")
	}
	defer docXML.Close()

	raw, err := io.ReadAll(docXML)
	if err != nil {
		return "", fmt.Errorf("чтение document.xml: %w", err)
	}

	re := regexp.MustCompile(`<w:t[^>]*>([^<]*)</w:t>`)
	matches := re.FindAllStringSubmatch(string(raw), -1)
	var parts []string
	for _, m := range matches {
		if len(m) > 1 && m[1] != "" {
			parts = append(parts, m[1])
		}
	}

	return strings.Join(parts, ""), nil
}

func extractXLSX(content []byte) (string, error) {
	f, err := excelize.OpenReader(bytes.NewReader(content))
	if err != nil {
		return "", fmt.Errorf("открытие XLSX: %w", err)
	}
	defer f.Close()

	var out strings.Builder
	for _, name := range f.GetSheetList() {
		rows, err := f.GetRows(name)
		if err != nil {
			return "", fmt.Errorf("чтение листа %q: %w", name, err)
		}

		if len(rows) == 0 {
			continue
		}

		out.WriteString(fmt.Sprintf("[Лист: %s]\n", name))
		for _, row := range rows {
			out.WriteString(strings.Join(row, "\t"))
			out.WriteString("\n")
		}
		out.WriteString("\n")
	}
	return strings.TrimSpace(out.String()), nil
}

func extractCSV(content []byte) (string, error) {
	r := csv.NewReader(bytes.NewReader(content))
	r.Comma = detectCSVSeparator(content)
	records, err := r.ReadAll()
	if err != nil {
		return "", fmt.Errorf("разбор CSV: %w", err)
	}

	var out strings.Builder
	for _, row := range records {
		out.WriteString(strings.Join(row, "\t"))
		out.WriteString("\n")
	}

	return strings.TrimSuffix(out.String(), "\n"), nil
}

func detectCSVSeparator(content []byte) rune {
	firstLine := string(content)
	if idx := bytes.IndexByte(content, '\n'); idx >= 0 {
		firstLine = string(content[:idx])
	}

	if strings.Contains(firstLine, ";") && !strings.Contains(firstLine, ",") {
		return ';'
	}

	return ','
}
