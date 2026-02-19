package pkg

import (
	"errors"
	"testing"

	"gorm.io/gorm"
)

func TestValidatePassword(t *testing.T) {
	tests := []struct {
		name     string
		password string
		wantErr  bool
	}{
		{"пустой пароль", "", true},
		{"короткий пароль", "short", true},
		{"7 символов", "1234567", true},
		{"8 символов", "12345678", false},
		{"длинный пароль", "validPassword123", false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidatePassword(tt.password)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidatePassword(%q): err = %v, ожидалась ошибка: %v", tt.password, err, tt.wantErr)
			}
		})
	}
}

func TestNormalizePagination(t *testing.T) {
	tests := []struct {
		page, pageSize, defaultSize int32
		wantPage, wantSize          int32
	}{
		{0, 0, 20, 1, 20},
		{1, 10, 20, 1, 10},
		{-1, 5, 20, 1, 5},
		{2, 0, 50, 2, 50},
		{3, 100, 20, 3, 100},
	}
	for _, tt := range tests {
		gotPage, gotSize := NormalizePagination(tt.page, tt.pageSize, tt.defaultSize)
		if gotPage != tt.wantPage || gotSize != tt.wantSize {
			t.Errorf("normalizePagination(%d, %d, %d) = %d, %d; ожидалось %d, %d", tt.page, tt.pageSize, tt.defaultSize, gotPage, gotSize, tt.wantPage, tt.wantSize)
		}
	}
}

func TestHandleNotFound(t *testing.T) {
	customErr := errors.New("другая ошибка")
	msg := "запись не найдена"

	tests := []struct {
		name    string
		err     error
		message string
		wantNil bool
		check   func(t *testing.T, err error)
	}{
		{"nil", nil, msg, true, nil},
		{"gorm ErrRecordNotFound", gorm.ErrRecordNotFound, msg, false, func(t *testing.T, err error) {
			if err == nil || err.Error() != msg {
				t.Errorf("ожидалось сообщение %q, получено %v", msg, err)
			}
		}},
		{"другая ошибка возвращается как есть", customErr, msg, false, func(t *testing.T, err error) {
			if err != customErr {
				t.Errorf("ожидалась исходная ошибка %v, получено %v", customErr, err)
			}
		}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := HandleNotFound(tt.err, tt.message)
			if tt.wantNil {
				if got != nil {
					t.Errorf("HandleNotFound(nil, ...) = %v, ожидалось nil", got)
				}
				return
			}

			if tt.check != nil {
				tt.check(t, got)
			}
		})
	}
}
