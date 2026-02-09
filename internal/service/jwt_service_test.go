package service

import (
	"testing"
	"time"

	"github.com/magomedcoder/legion/internal/config"
	"github.com/magomedcoder/legion/internal/domain"
)

func TestNewJWTService(t *testing.T) {
	cfg, _ := config.Load()
	svc := NewJWTService(cfg)
	if svc == nil {
		t.Fatal("NewJWTService не должен возвращать nil")
	}
}

func TestJWTService_HashPassword_CheckPassword(t *testing.T) {
	cfg := &config.Config{
		JWT: config.JWTConfig{
			AccessSecret:  "s",
			RefreshSecret: "s",
		},
	}
	svc := NewJWTService(cfg)
	pass := "password123"
	hashed, err := svc.HashPassword(pass)
	if err != nil {
		t.Fatalf("HashPassword: %v", err)
	}

	if hashed == pass || len(hashed) == 0 {
		t.Error("хеш пароля должен отличаться и быть непустым")
	}

	if !svc.CheckPassword(hashed, pass) {
		t.Error("CheckPassword(hashed, pass) должен быть true")
	}

	if svc.CheckPassword(hashed, "wrong") {
		t.Error("CheckPassword(hashed, wrong) должен быть false")
	}
}

func TestJWTService_GenerateAccessToken_ValidateAccessToken(t *testing.T) {
	cfg := &config.Config{
		JWT: config.JWTConfig{
			AccessSecret:  "test-secret",
			RefreshSecret: "test-secret",
			AccessTTL: config.Duration{
				Duration: 15 * time.Minute,
			},
			RefreshTTL: config.Duration{
				Duration: 24 * time.Hour,
			},
		},
	}
	svc := NewJWTService(cfg)
	user := &domain.User{
		Id:       1,
		Username: "test1",
	}
	token, _, err := svc.GenerateAccessToken(user)
	if err != nil {
		t.Fatalf("GenerateAccessToken: %v", err)
	}

	claims, err := svc.ValidateAccessToken(token)
	if err != nil {
		t.Fatalf("ValidateAccessToken: %v", err)
	}

	if claims.UserId != 1 || claims.Username != "test1" {
		t.Errorf("claims неверные: %+v", claims)
	}
}

func TestJWTService_ValidateAccessToken_invalid(t *testing.T) {
	cfg := &config.Config{
		JWT: config.JWTConfig{
			AccessSecret:  "s",
			RefreshSecret: "s",
		},
	}
	svc := NewJWTService(cfg)
	_, err := svc.ValidateAccessToken("invalid.jwt.token")
	if err == nil {
		t.Error("ожидалась ошибка для невалидного токена")
	}
}
