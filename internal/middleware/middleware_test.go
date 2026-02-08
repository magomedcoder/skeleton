package middleware

import (
	"context"
	"errors"
	"testing"

	"github.com/magomedcoder/skeleton/internal/domain"
	"github.com/magomedcoder/skeleton/internal/usecase"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

var _ usecase.TokenValidator = (*fakeTokenValidator)(nil)

type fakeTokenValidator struct {
	user *domain.User
	err  error
}

func (f *fakeTokenValidator) ValidateToken(_ context.Context, _ string) (*domain.User, error) {
	if f.err != nil {
		return nil, f.err
	}

	return f.user, nil
}

func Test_extractToken(t *testing.T) {
	tests := []struct {
		name    string
		ctx     context.Context
		want    string
		wantErr bool
		code    codes.Code
	}{
		{
			name:    "нет метаданных",
			ctx:     context.Background(),
			wantErr: true,
			code:    codes.Unauthenticated,
		},
		{
			name:    "нет заголовка authorization",
			ctx:     metadata.NewIncomingContext(context.Background(), metadata.Pairs("other", "value")),
			wantErr: true,
			code:    codes.Unauthenticated,
		},
		{
			name:    "пустой authorization",
			ctx:     metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "")),
			wantErr: true,
			code:    codes.Unauthenticated,
		},
		{
			name:    "неверный формат — без Bearer",
			ctx:     metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "token123")),
			wantErr: true,
			code:    codes.Unauthenticated,
		},
		{
			name:    "неверный формат — только Bearer без пробела",
			ctx:     metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "Bearer")),
			wantErr: true,
			code:    codes.Unauthenticated,
		},
		{
			name:    "успех",
			ctx:     metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "Bearer my-jwt-token")),
			want:    "my-jwt-token",
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := extractToken(tt.ctx)
			if (err != nil) != tt.wantErr {
				t.Errorf("extractToken() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if !tt.wantErr && got != tt.want {
				t.Errorf("extractToken() = %q, want %q", got, tt.want)
			}

			if err != nil && tt.code != codes.Unknown {
				if st, ok := status.FromError(err); ok && st.Code() != tt.code {
					t.Errorf("extractToken() status code = %v, want %v", st.Code(), tt.code)
				}
			}
		})
	}
}

func TestGetUserFromContext(t *testing.T) {
	adminUser := &domain.User{
		Id:       1,
		Username: "admin",
		Role:     domain.UserRoleAdmin,
	}
	customErr := errors.New("invalid token")

	tests := []struct {
		name      string
		ctx       context.Context
		validator usecase.TokenValidator
		wantUser  *domain.User
		wantErr   bool
		wantCode  codes.Code
	}{
		{
			name:      "нет метаданных",
			ctx:       context.Background(),
			validator: &fakeTokenValidator{user: adminUser},
			wantErr:   true,
			wantCode:  codes.Unauthenticated,
		},
		{
			name:      "неверный формат заголовка",
			ctx:       metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "Basic xxx")),
			validator: &fakeTokenValidator{user: adminUser},
			wantErr:   true,
			wantCode:  codes.Unauthenticated,
		},
		{
			name:      "ValidateToken возвращает ошибку",
			ctx:       metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "Bearer tok")),
			validator: &fakeTokenValidator{err: customErr},
			wantErr:   true,
			wantCode:  codes.Unauthenticated,
		},
		{
			name:      "успех",
			ctx:       metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "Bearer tok")),
			validator: &fakeTokenValidator{user: adminUser},
			wantUser:  adminUser,
			wantErr:   false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := GetUserFromContext(tt.ctx, tt.validator)
			if (err != nil) != tt.wantErr {
				t.Errorf("GetUserFromContext() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if tt.wantErr {
				if tt.wantCode != codes.Unknown {
					st, ok := status.FromError(err)
					if !ok || st.Code() != tt.wantCode {
						t.Errorf("GetUserFromContext() status code = %v, want %v", st.Code(), tt.wantCode)
					}
				}
				return
			}

			if got != tt.wantUser {
				t.Errorf("GetUserFromContext() user = %+v, want %+v", got, tt.wantUser)
			}
		})
	}
}

func TestRequireAdmin(t *testing.T) {
	adminUser := &domain.User{
		Id:       1,
		Username: "admin",
		Role:     domain.UserRoleAdmin,
	}
	regularUser := &domain.User{
		Id:       2,
		Username: "user",
		Role:     domain.UserRoleUser,
	}
	ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "Bearer tok"))

	tests := []struct {
		name      string
		validator usecase.TokenValidator
		wantErr   bool
		wantCode  codes.Code
	}{
		{
			name:      "ошибка авторизации",
			validator: &fakeTokenValidator{err: errors.New("bad token")},
			wantErr:   true,
			wantCode:  codes.Unauthenticated,
		},
		{
			name:      "пользователь не администратор",
			validator: &fakeTokenValidator{user: regularUser},
			wantErr:   true,
			wantCode:  codes.PermissionDenied,
		},
		{
			name:      "администратор — успех",
			validator: &fakeTokenValidator{user: adminUser},
			wantErr:   false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := RequireAdmin(ctx, tt.validator)
			if (err != nil) != tt.wantErr {
				t.Errorf("RequireAdmin() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if tt.wantErr && tt.wantCode != codes.Unknown {
				st, ok := status.FromError(err)
				if !ok || st.Code() != tt.wantCode {
					t.Errorf("RequireAdmin() status code = %v, want %v", st.Code(), tt.wantCode)
				}
			}
		})
	}
}
