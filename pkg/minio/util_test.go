package minio

import (
	"bytes"
	"mime/multipart"
	"net/http"
	"testing"
)

func TestReadMultipartStream(t *testing.T) {
	body := new(bytes.Buffer)
	w := multipart.NewWriter(body)
	part, err := w.CreateFormFile("file", "test.txt")
	if err != nil {
		t.Fatalf("CreateFormFile: %v", err)
	}

	_, _ = part.Write([]byte("hello"))
	_ = w.Close()

	req, err := http.NewRequest("POST", "/", bytes.NewReader(body.Bytes()))
	if err != nil {
		t.Fatalf("NewRequest: %v", err)
	}

	req.Header.Set("Content-Type", w.FormDataContentType())
	if err := req.ParseMultipartForm(1 << 20); err != nil {
		t.Fatalf("ParseMultipartForm: %v", err)
	}

	if len(req.MultipartForm.File["file"]) == 0 {
		t.Fatal("нет файла в форме")
	}

	fileHeader := req.MultipartForm.File["file"][0]
	data, err := ReadMultipartStream(fileHeader)
	if err != nil {
		t.Fatalf("ReadMultipartStream: %v", err)
	}

	if string(data) != "hello" {
		t.Errorf("ReadMultipartStream = %q, ожидалось \"hello\"", string(data))
	}
}
