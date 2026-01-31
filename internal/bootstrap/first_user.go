package bootstrap

import (
	"context"
	"fmt"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/service"
	"time"
)

func CreateFirstUser(ctx context.Context, userRepo domain.UserRepository, jwtService *service.JWTService) error {
	username, password, name, surname := "legion", "password", "Admin", "Admin"

	_, total, err := userRepo.List(ctx, 1, 1)
	if err != nil {
		return fmt.Errorf("ошибка проверки существующих пользователей: %w", err)
	}
	if total > 0 {
		return nil
	}

	hashed, err := jwtService.HashPassword(password)
	if err != nil {
		return fmt.Errorf("ошибка хеширования пароля: %w", err)
	}

	user := &domain.User{
		Username:  username,
		Password:  hashed,
		Name:      name,
		Surname:   surname,
		Role:      domain.UserRoleAdmin,
		CreatedAt: time.Now(),
	}
	if err := userRepo.Create(ctx, user); err != nil {
		return fmt.Errorf("ошибка создания первого пользователя: %w", err)
	}

	return nil
}
