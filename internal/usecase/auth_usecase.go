package usecase

import (
	"context"
	"errors"
	"strings"

	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/service"
	"github.com/magomedcoder/legion/pkg"
	"github.com/magomedcoder/legion/pkg/logger"
)

const maxDevicesPerUser = 4

type TokenValidator interface {
	ValidateToken(ctx context.Context, token string) (*domain.User, error)
}

type AuthUseCase struct {
	userRepo        domain.UserRepository
	userSessionRepo domain.UserSessionRepository
	jwtService      *service.JWTService
}

func NewAuthUseCase(
	userRepo domain.UserRepository,
	userSessionRepo domain.UserSessionRepository,
	jwtService *service.JWTService,
) *AuthUseCase {
	return &AuthUseCase{
		userRepo:        userRepo,
		userSessionRepo: userSessionRepo,
		jwtService:      jwtService,
	}
}

func (a *AuthUseCase) Login(ctx context.Context, username, password string) (*domain.User, string, string, error) {
	logger.D("AuthUseCase: вход пользователя %s", username)
	user, err := a.userRepo.GetByUsername(ctx, username)
	if err != nil {
		logger.W("AuthUseCase: пользователь не найден: %s", username)
		return nil, "", "", errors.New("неверные учетные данные")
	}

	if !a.jwtService.CheckPassword(user.Password, password) {
		logger.W("AuthUseCase: неверный пароль для %s", username)
		return nil, "", "", errors.New("неверные учетные данные")
	}

	accessToken, accessExpires, err := a.jwtService.GenerateAccessToken(user)
	if err != nil {
		logger.E("AuthUseCase: ошибка генерации access token: %v", err)
		return nil, "", "", err
	}

	refreshToken, refreshExpires, err := a.jwtService.GenerateRefreshToken(user)
	if err != nil {
		return nil, "", "", err
	}

	if err := a.ensureMaxDevices(ctx, user.Id); err != nil {
		return nil, "", "", err
	}

	accessTokenEntity := domain.NewToken(user.Id, accessToken, domain.TokenTypeAccess, accessExpires)
	refreshTokenEntity := domain.NewToken(user.Id, refreshToken, domain.TokenTypeRefresh, refreshExpires)

	if err := a.userSessionRepo.Create(ctx, accessTokenEntity); err != nil {
		return nil, "", "", err
	}

	if err := a.userSessionRepo.Create(ctx, refreshTokenEntity); err != nil {
		return nil, "", "", err
	}

	user.Password = ""

	return user, accessToken, refreshToken, nil
}

func (a *AuthUseCase) RefreshToken(ctx context.Context, refreshToken string) (string, string, error) {
	claims, err := a.jwtService.ValidateRefreshToken(refreshToken)
	if err != nil {
		return "", "", errors.New("неверный токен обновления")
	}

	token, err := a.userSessionRepo.GetByToken(ctx, refreshToken)
	if err != nil || token.IsExpired() {
		return "", "", errors.New("неверный токен обновления")
	}

	user, err := a.userRepo.GetById(ctx, claims.UserId)
	if err != nil {
		return "", "", errors.New("пользователь не найден")
	}

	accessToken, accessExpires, err := a.jwtService.GenerateAccessToken(user)
	if err != nil {
		return "", "", err
	}

	newRefreshToken, refreshExpires, err := a.jwtService.GenerateRefreshToken(user)
	if err != nil {
		return "", "", err
	}

	_ = a.userSessionRepo.DeleteByToken(ctx, refreshToken)

	if err := a.ensureMaxDevices(ctx, user.Id); err != nil {
		return "", "", err
	}

	accessTokenEntity := domain.NewToken(user.Id, accessToken, domain.TokenTypeAccess, accessExpires)
	refreshTokenEntity := domain.NewToken(user.Id, newRefreshToken, domain.TokenTypeRefresh, refreshExpires)

	if err := a.userSessionRepo.Create(ctx, accessTokenEntity); err != nil {
		return "", "", err
	}

	if err := a.userSessionRepo.Create(ctx, refreshTokenEntity); err != nil {
		return "", "", err
	}

	return accessToken, newRefreshToken, nil
}

func (a *AuthUseCase) ensureMaxDevices(ctx context.Context, userID int) error {
	count, err := a.userSessionRepo.CountByUserIdAndType(ctx, userID, domain.TokenTypeRefresh)
	if err != nil {
		return err
	}

	if count >= maxDevicesPerUser {
		toRemove := count - maxDevicesPerUser + 1
		if err := a.userSessionRepo.DeleteOldestByUserIdAndType(ctx, userID, domain.TokenTypeRefresh, toRemove); err != nil {
			return err
		}
	}

	return nil
}

func (a *AuthUseCase) ValidateToken(ctx context.Context, token string) (*domain.User, error) {
	claims, err := a.jwtService.ValidateAccessToken(token)
	if err != nil {
		return nil, errors.New("неверный токен")
	}

	tokenEntity, err := a.userSessionRepo.GetByToken(ctx, token)
	if err != nil || tokenEntity.IsExpired() {
		return nil, errors.New("неверный токен")
	}

	user, err := a.userRepo.GetById(ctx, claims.UserId)
	if err != nil {
		return nil, errors.New("пользователь не найден")
	}

	_ = a.userRepo.UpdateLastVisitedAt(ctx, user.Id)

	user.Password = ""

	return user, nil
}

func (a *AuthUseCase) Logout(ctx context.Context, UserId int) error {
	if err := a.userSessionRepo.DeleteByUserId(ctx, UserId, domain.TokenTypeAccess); err != nil {
		return err
	}

	if err := a.userSessionRepo.DeleteByUserId(ctx, UserId, domain.TokenTypeRefresh); err != nil {
		return err
	}

	return nil
}

func (a *AuthUseCase) GetDevices(ctx context.Context, userID int) ([]*domain.Token, error) {
	tokens, err := a.userSessionRepo.ListByUserIdAndType(ctx, userID, domain.TokenTypeRefresh)
	if err != nil {
		return nil, err
	}

	return tokens, nil
}

func (a *AuthUseCase) RevokeDevice(ctx context.Context, userID int, deviceID int) error {
	return a.userSessionRepo.DeleteByIdAndUserId(ctx, deviceID, userID)
}

func (a *AuthUseCase) ChangePassword(ctx context.Context, UserId int, oldPassword, newPassword, currentRefreshToken string) error {
	if oldPassword == "" {
		return errors.New("текущий пароль не может быть пустым")
	}
	if err := pkg.ValidatePassword(newPassword); err != nil {
		return err
	}

	user, err := a.userRepo.GetById(ctx, UserId)
	if err != nil {
		return err
	}

	if !a.jwtService.CheckPassword(user.Password, oldPassword) {
		return errors.New("неверный текущий пароль")
	}

	hashed, err := a.jwtService.HashPassword(newPassword)
	if err != nil {
		return err
	}

	user.Password = hashed
	if err := a.userRepo.Update(ctx, user); err != nil {
		return err
	}

	_ = a.userSessionRepo.DeleteByUserId(ctx, UserId, domain.TokenTypeAccess)

	if keepToken := strings.TrimSpace(currentRefreshToken); keepToken != "" {
		_ = a.userSessionRepo.DeleteRefreshTokensByUserIdExcept(ctx, UserId, keepToken)
	}

	return nil
}
