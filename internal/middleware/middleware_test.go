package middleware

import (
	"context"
	"errors"
	"testing"

	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/usecase"
	"google.golang.org/grpc"
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
			name:    "неверный формат - без Bearer",
			ctx:     metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "token123")),
			wantErr: true,
			code:    codes.Unauthenticated,
		},
		{
			name:    "неверный формат - только Bearer без пробела",
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

func TestGetSession(t *testing.T) {
	t.Run("контекст без сессии — nil", func(t *testing.T) {
		got := GetSession(context.Background())
		if got != nil {
			t.Errorf("GetSession() = %v, ожидался nil", got)
		}
	})

	t.Run("контекст с сессией — возвращает сессию", func(t *testing.T) {
		want := &JSession{Uid: 42}
		ctx := context.WithValue(context.Background(), sessionKey, want)
		got := GetSession(ctx)
		if got != want {
			t.Errorf("GetSession() = %v, ожидался %v", got, want)
		}
		if got != nil && got.Uid != 42 {
			t.Errorf("GetSession().Uid = %d, ожидалось 42", got.Uid)
		}
	})

	t.Run("контекст с значением другого типа — nil", func(t *testing.T) {
		ctx := context.WithValue(context.Background(), sessionKey, "not a session")
		got := GetSession(ctx)
		if got != nil {
			t.Errorf("GetSession() = %v, ожидался nil при неверном типе", got)
		}
	})
}

func TestUnaryAuthInterceptor_noToken_returnsUnauthenticated(t *testing.T) {
	validator := &fakeTokenValidator{user: &domain.User{Id: 1, Role: domain.UserRoleUser}}
	mw := NewMiddleware(validator)
	ctx := context.Background()
	info := &grpc.UnaryServerInfo{FullMethod: "/some.Service/SomeMethod"}
	handler := func(ctx context.Context, req any) (any, error) { return "ok", nil }

	_, err := mw.UnaryAuthInterceptor(ctx, nil, info, handler)
	if err == nil {
		t.Fatal("UnaryAuthInterceptor: ожидалась ошибка без токена")
	}
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("UnaryAuthInterceptor: код %v, ожидался Unauthenticated", code)
	}
}

func TestUnaryAuthInterceptor_validToken_callsHandlerAndSetsSession(t *testing.T) {
	user := &domain.User{Id: 10, Username: "u", Role: domain.UserRoleUser}
	validator := &fakeTokenValidator{user: user}
	mw := NewMiddleware(validator)
	ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "Bearer tok"))
	info := &grpc.UnaryServerInfo{FullMethod: "/some.Service/SomeMethod"}
	var gotSession *JSession
	handler := func(ctx context.Context, req any) (any, error) {
		gotSession = GetSession(ctx)
		return "ok", nil
	}

	resp, err := mw.UnaryAuthInterceptor(ctx, nil, info, handler)
	if err != nil {
		t.Fatalf("UnaryAuthInterceptor: %v", err)
	}
	if resp != "ok" {
		t.Errorf("UnaryAuthInterceptor: ответ = %v, ожидался ok", resp)
	}
	if gotSession == nil {
		t.Fatal("UnaryAuthInterceptor: сессия не передана в handler")
	}
	if gotSession.Uid != user.Id {
		t.Errorf("UnaryAuthInterceptor: session.Uid = %d, ожидалось %d", gotSession.Uid, user.Id)
	}
}

func TestUnaryAuthInterceptor_invalidToken_returnsUnauthenticated(t *testing.T) {
	validator := &fakeTokenValidator{err: errors.New("invalid token")}
	mw := NewMiddleware(validator)
	ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "Bearer bad"))
	info := &grpc.UnaryServerInfo{FullMethod: "/some.Service/SomeMethod"}
	handler := func(ctx context.Context, req any) (any, error) { return nil, nil }

	_, err := mw.UnaryAuthInterceptor(ctx, nil, info, handler)
	if err == nil {
		t.Fatal("UnaryAuthInterceptor: ожидалась ошибка при неверном токене")
	}
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("UnaryAuthInterceptor: код %v, ожидался Unauthenticated", code)
	}
}
