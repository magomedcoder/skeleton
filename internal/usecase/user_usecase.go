package usecase

import (
	"context"
	"errors"
	"github.com/magomedcoder/skeleton/pkg"
	"strconv"
	"strings"
	"time"

	"github.com/magomedcoder/skeleton/internal/domain"
	"github.com/magomedcoder/skeleton/internal/service"
)

type UserUseCase struct {
	userRepo   domain.UserRepository
	tokenRepo  domain.TokenRepository
	jwtService *service.JWTService
}

func NewUserUseCase(userRepo domain.UserRepository, tokenRepo domain.TokenRepository, jwtService *service.JWTService) *UserUseCase {
	return &UserUseCase{
		userRepo:   userRepo,
		tokenRepo:  tokenRepo,
		jwtService: jwtService,
	}
}

func (u *UserUseCase) GetUsers(ctx context.Context, page, pageSize int32) ([]*domain.User, int32, error) {
	users, total, err := u.userRepo.List(ctx, page, pageSize)
	if err != nil {
		return nil, 0, err
	}
	for _, user := range users {
		user.Password = ""
	}
	return users, total, nil
}

func (u *UserUseCase) CreateUser(ctx context.Context, username, password, name, surname string, role int32) (*domain.User, error) {
	username = strings.TrimSpace(username)
	name = strings.TrimSpace(name)
	surname = strings.TrimSpace(surname)

	if username == "" || name == "" {
		return nil, errors.New("username и name обязательны")
	}

	if err := pkg.ValidatePassword(password); err != nil {
		return nil, err
	}

	existing, err := u.userRepo.GetByUsername(ctx, username)
	if err == nil && existing != nil {
		return nil, errors.New("пользователь с таким username уже существует")
	}

	hashed, err := u.jwtService.HashPassword(password)
	if err != nil {
		return nil, err
	}

	userRole := domain.UserRoleUser
	if role == int32(domain.UserRoleAdmin) {
		userRole = domain.UserRoleAdmin
	}

	user := &domain.User{
		Username:  username,
		Password:  hashed,
		Name:      name,
		Surname:   surname,
		Role:      userRole,
		CreatedAt: time.Now(),
	}

	if err := u.userRepo.Create(ctx, user); err != nil {
		return nil, err
	}

	user.Password = ""
	return user, nil
}

func (u *UserUseCase) EditUser(ctx context.Context, id string, username, password, name, surname string, role int32) (*domain.User, error) {
	intID, err := strconv.Atoi(id)
	if err != nil {
		return nil, errors.New("неверный id пользователя")
	}

	existing, err := u.userRepo.GetById(ctx, intID)
	if err != nil {
		return nil, err
	}

	username = strings.TrimSpace(username)
	name = strings.TrimSpace(name)
	surname = strings.TrimSpace(surname)

	if username == "" || name == "" {
		return nil, errors.New("username и name обязательны")
	}

	existing.Username = username
	existing.Name = name
	existing.Surname = surname

	newRole := domain.UserRoleUser
	if role == int32(domain.UserRoleAdmin) {
		newRole = domain.UserRoleAdmin
	}
	roleChanged := existing.Role != newRole
	existing.Role = newRole

	if strings.TrimSpace(password) != "" {
		if err := pkg.ValidatePassword(password); err != nil {
			return nil, err
		}

		hashed, err := u.jwtService.HashPassword(password)
		if err != nil {
			return nil, err
		}

		existing.Password = hashed
	} else {
		existing.Password = ""
	}

	if err := u.userRepo.Update(ctx, existing); err != nil {
		return nil, err
	}

	updated, err := u.userRepo.GetById(ctx, intID)
	if err != nil {
		return nil, err
	}
	updated.Password = ""

	if roleChanged {
		_ = u.tokenRepo.DeleteByUserId(ctx, intID, domain.TokenTypeAccess)
		_ = u.tokenRepo.DeleteByUserId(ctx, intID, domain.TokenTypeRefresh)
	}

	return updated, nil
}
