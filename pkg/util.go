package pkg

import (
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"gorm.io/gorm"
)

const (
	minPasswordLength = 8
)

func ValidatePassword(password string) error {
	if password == "" {
		return errors.New("пароль не может быть пустым")
	}

	if len(password) < minPasswordLength {
		return errors.New("пароль должен содержать минимум 8 символов")
	}

	return nil
}

func NormalizePagination(page, pageSize, defaultPageSize int32) (int32, int32) {
	if page <= 0 {
		page = 1
	}
	if pageSize <= 0 {
		pageSize = defaultPageSize
	}

	return page, pageSize
}

func HandleNotFound(err error, message string) error {
	if errors.Is(err, pgx.ErrNoRows) || errors.Is(err, gorm.ErrRecordNotFound) {
		return errors.New(message)
	}

	return err
}

func GenerateUUID() string {
	return uuid.New().String()
}
