package usecase

import (
	"context"
	"errors"

	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/service"
)

type AuthUseCase struct {
	userRepo   domain.UserRepository
	tokenRepo  domain.TokenRepository
	jwtService *service.JWTService
}

func NewAuthUseCase(
	userRepo domain.UserRepository,
	tokenRepo domain.TokenRepository,
	jwtService *service.JWTService,
) *AuthUseCase {
	return &AuthUseCase{
		userRepo:   userRepo,
		tokenRepo:  tokenRepo,
		jwtService: jwtService,
	}
}

func (a *AuthUseCase) Login(ctx context.Context, username, password string) (*domain.User, string, string, error) {
	user, err := a.userRepo.GetByUsername(ctx, username)
	if err != nil {
		return nil, "", "", errors.New("неверные учетные данные")
	}

	if !a.jwtService.CheckPassword(user.Password, password) {
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

	_ = a.tokenRepo.DeleteByUserId(ctx, user.Id, domain.TokenTypeAccess)
	_ = a.tokenRepo.DeleteByUserId(ctx, user.Id, domain.TokenTypeRefresh)

	accessTokenEntity := domain.NewToken(user.Id, accessToken, domain.TokenTypeAccess, accessExpires)
	refreshTokenEntity := domain.NewToken(user.Id, refreshToken, domain.TokenTypeRefresh, refreshExpires)

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

	user, err := a.userRepo.GetById(ctx, claims.UserID)
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

	_ = a.tokenRepo.DeleteByUserId(ctx, user.Id, domain.TokenTypeAccess)
	_ = a.tokenRepo.DeleteByToken(ctx, refreshToken)

	accessTokenEntity := domain.NewToken(user.Id, accessToken, domain.TokenTypeAccess, accessExpires)
	refreshTokenEntity := domain.NewToken(user.Id, newRefreshToken, domain.TokenTypeRefresh, refreshExpires)

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

	user, err := a.userRepo.GetById(ctx, claims.UserID)
	if err != nil {
		return nil, errors.New("пользователь не найден")
	}

	user.Password = ""

	return user, nil
}

func (a *AuthUseCase) Logout(ctx context.Context, userID int) error {
	if err := a.tokenRepo.DeleteByUserId(ctx, userID, domain.TokenTypeAccess); err != nil {
		return err
	}

	if err := a.tokenRepo.DeleteByUserId(ctx, userID, domain.TokenTypeRefresh); err != nil {
		return err
	}

	return nil
}
