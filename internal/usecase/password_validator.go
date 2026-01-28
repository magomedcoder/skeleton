package usecase

import "errors"

const (
	minPasswordLength = 8
)

func validatePassword(password string) error {
	if password == "" {
		return errors.New("пароль не может быть пустым")
	}
	if len(password) < minPasswordLength {
		return errors.New("пароль должен содержать минимум 8 символов")
	}
	return nil
}
