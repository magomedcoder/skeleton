package handler

import (
	"context"
	"strings"

	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/usecase"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

func extractToken(ctx context.Context) (string, error) {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return "", status.Error(codes.Unauthenticated, "метаданные не предоставлены")
	}

	authHeaders := md.Get("authorization")
	if len(authHeaders) == 0 {
		return "", status.Error(codes.Unauthenticated, "заголовок авторизации не предоставлен")
	}

	authHeader := authHeaders[0]
	if !strings.HasPrefix(authHeader, "Bearer ") {
		return "", status.Error(codes.Unauthenticated, "неверный формат заголовка авторизации")
	}

	return strings.TrimPrefix(authHeader, "Bearer "), nil
}

func getUserFromContext(ctx context.Context, authUseCase *usecase.AuthUseCase) (*domain.User, error) {
	token, err := extractToken(ctx)
	if err != nil {
		return nil, err
	}

	user, err := authUseCase.ValidateToken(ctx, token)
	if err != nil {
		return nil, status.Error(codes.Unauthenticated, err.Error())
	}

	return user, nil
}

func requireAdmin(ctx context.Context, authUseCase *usecase.AuthUseCase) error {
	user, err := getUserFromContext(ctx, authUseCase)
	if err != nil {
		return err
	}

	if user.Role != domain.UserRoleAdmin {
		return status.Error(codes.PermissionDenied, "доступ разрешён только администратору")
	}

	return nil
}
