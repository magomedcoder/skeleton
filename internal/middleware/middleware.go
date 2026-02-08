package middleware

import (
	"context"
	error2 "github.com/magomedcoder/legion/pkg/error"
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

func GetUserFromContext(ctx context.Context, authUseCase usecase.TokenValidator) (*domain.User, error) {
	token, err := extractToken(ctx)
	if err != nil {
		return nil, err
	}

	user, err := authUseCase.ValidateToken(ctx, token)
	if err != nil {
		return nil, error2.ToStatusError(codes.Unauthenticated, err)
	}

	return user, nil
}

func RequireAdmin(ctx context.Context, authUseCase usecase.TokenValidator) error {
	user, err := GetUserFromContext(ctx, authUseCase)
	if err != nil {
		return err
	}

	if user.Role != domain.UserRoleAdmin {
		return status.Error(codes.PermissionDenied, "доступ разрешён только администратору")
	}

	return nil
}
