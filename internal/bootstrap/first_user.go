package bootstrap

import (
	"context"
	"fmt"
	"time"

	"github.com/magomedcoder/skeleton/internal/domain"
	"github.com/magomedcoder/skeleton/internal/service"
	"github.com/magomedcoder/skeleton/pkg/logger"
)

func CreateFirstUser(ctx context.Context, userRepo domain.UserRepository, jwtService *service.JWTService) error {
	username, password, name, surname := "skeleton", "password", "Admin", "Admin"

	_, total, err := userRepo.List(ctx, 1, 1)
	if err != nil {
		return fmt.Errorf("ошибка проверки существующих пользователей: %w", err)
	}
	if total > 0 {
		logger.D("Bootstrap: пользователи уже есть, первый пользователь не создаётся")
		return nil
	}
	logger.I("Bootstrap: создание первого пользователя %s", username)

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
	logger.I("Bootstrap: первый пользователь создан")

	return nil
}
