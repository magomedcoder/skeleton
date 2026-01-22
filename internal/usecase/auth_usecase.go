package usecase

import (
	"context"
	"errors"

	"github.com/magomedcoder/assist/internal/domain"
	"github.com/magomedcoder/assist/internal/service"
)

type AuthUseCase struct {
	userRepo        domain.UserRepository
	tokenRepo       domain.TokenRepository
	jwtService      *service.JWTService
	passwordService *service.PasswordService
}

func NewAuthUseCase(
	userRepo domain.UserRepository,
	tokenRepo domain.TokenRepository,
	jwtService *service.JWTService,
	passwordService *service.PasswordService,
) *AuthUseCase {
	return &AuthUseCase{
		userRepo:        userRepo,
		tokenRepo:       tokenRepo,
		jwtService:      jwtService,
		passwordService: passwordService,
	}
}

func (a *AuthUseCase) Login(ctx context.Context, email, password string) (*domain.User, string, string, error) {
	user, err := a.userRepo.GetByEmail(ctx, email)
	if err != nil {
		return nil, "", "", errors.New("неверные учетные данные")
	}

	if !a.passwordService.CheckPassword(user.Password, password) {
		return nil, "", "", errors.New("неверные учетные данные")
	}

	accessToken, accessExpires, err := a.jwtService.GenerateAccessToken(user)
	if err != nil {
		return nil, "", "", err
	}

	refreshToken, refreshExpires, err := a.jwtService.GenerateRefreshToken(user)
	if err != nil {
		return nil, "", "", err
	}

	_ = a.tokenRepo.DeleteByUserID(ctx, user.ID, domain.TokenTypeAccess)
	_ = a.tokenRepo.DeleteByUserID(ctx, user.ID, domain.TokenTypeRefresh)

	accessTokenEntity := domain.NewToken(user.ID, accessToken, domain.TokenTypeAccess, accessExpires)
	refreshTokenEntity := domain.NewToken(user.ID, refreshToken, domain.TokenTypeRefresh, refreshExpires)

	if err := a.tokenRepo.Create(ctx, accessTokenEntity); err != nil {
		return nil, "", "", err
	}

	if err := a.tokenRepo.Create(ctx, refreshTokenEntity); err != nil {
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

	token, err := a.tokenRepo.GetByToken(ctx, refreshToken)
	if err != nil || token.IsExpired() {
		return "", "", errors.New("неверный токен обновления")
	}

	user, err := a.userRepo.GetByID(ctx, claims.UserID)
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

	_ = a.tokenRepo.DeleteByUserID(ctx, user.ID, domain.TokenTypeAccess)
	_ = a.tokenRepo.DeleteByToken(ctx, refreshToken)

	accessTokenEntity := domain.NewToken(user.ID, accessToken, domain.TokenTypeAccess, accessExpires)
	refreshTokenEntity := domain.NewToken(user.ID, newRefreshToken, domain.TokenTypeRefresh, refreshExpires)

	if err := a.tokenRepo.Create(ctx, accessTokenEntity); err != nil {
		return "", "", err
	}

	if err := a.tokenRepo.Create(ctx, refreshTokenEntity); err != nil {
		return "", "", err
	}

	return accessToken, newRefreshToken, nil
}

func (a *AuthUseCase) ValidateToken(ctx context.Context, token string) (*domain.User, error) {
	claims, err := a.jwtService.ValidateAccessToken(token)
	if err != nil {
		return nil, errors.New("неверный токен")
	}

	tokenEntity, err := a.tokenRepo.GetByToken(ctx, token)
	if err != nil || tokenEntity.IsExpired() {
		return nil, errors.New("неверный токен")
	}

	user, err := a.userRepo.GetByID(ctx, claims.UserID)
	if err != nil {
		return nil, errors.New("пользователь не найден")
	}

	user.Password = ""

	return user, nil
}

func (a *AuthUseCase) Logout(ctx context.Context, userID int) error {
	if err := a.tokenRepo.DeleteByUserID(ctx, userID, domain.TokenTypeAccess); err != nil {
		return err
	}

	if err := a.tokenRepo.DeleteByUserID(ctx, userID, domain.TokenTypeRefresh); err != nil {
		return err
	}

	return nil
}
