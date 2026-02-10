package middleware

import (
	"context"
	"strings"
	"sync"

	"github.com/magomedcoder/legion/api/pb/commonpb"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/usecase"
	error2 "github.com/magomedcoder/legion/pkg/error"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protoreflect"
	"google.golang.org/protobuf/reflect/protoregistry"
)

const sessionKey = "__LEGION_SESSION__"

type JSession struct {
	Uid int
}

type MethodConfig struct {
	Role     domain.UserRole
	SkipAuth bool
}

type Middleware struct {
	mu          sync.RWMutex
	methodCache map[string]*MethodConfig
	authUseCase usecase.TokenValidator
}

func NewMiddleware(authUseCase usecase.TokenValidator, _ ...string) *Middleware {
	return &Middleware{
		methodCache: make(map[string]*MethodConfig),
		authUseCase: authUseCase,
	}
}

func (m *Middleware) UnaryAuthInterceptor(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
	config := m.getMethodConfig(info.FullMethod)
	if config.SkipAuth {
		return handler(ctx, req)
	}

	user, err := m.getUserFromContext(ctx, info.FullMethod)
	if err != nil {
		return nil, err
	}

	ctx = context.WithValue(ctx, sessionKey, &JSession{Uid: user.Id})
	return handler(ctx, req)
}

type wrappedStream struct {
	grpc.ServerStream
	ctx context.Context
}

func (w *wrappedStream) Context() context.Context {
	return w.ctx
}

func (m *Middleware) StreamAuthInterceptor(srv any, ss grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
	_ctx := ss.Context()

	config := m.getMethodConfig(info.FullMethod)
	if config.SkipAuth {
		return handler(srv, ss)
	}

	user, err := m.getUserFromContext(_ctx, info.FullMethod)
	if err != nil {
		return err
	}

	ctx := context.WithValue(_ctx, sessionKey, &JSession{Uid: user.Id})
	wrapped := &wrappedStream{ServerStream: ss, ctx: ctx}
	return handler(srv, wrapped)
}

func (m *Middleware) getUserFromContext(ctx context.Context, fullMethod string) (*domain.User, error) {
	user, err := GetUserFromContext(ctx, m.authUseCase)
	if err != nil {
		return nil, err
	}

	config := m.getMethodConfig(fullMethod)
	if user.Role < config.Role {
		return nil, status.Error(codes.PermissionDenied, "недостаточно прав для вызова метода")
	}

	return user, nil
}

func GetSession(ctx context.Context) *JSession {
	v := ctx.Value(sessionKey)
	if v == nil {
		return nil
	}
	if s, ok := v.(*JSession); ok {
		return s
	}
	return nil
}

func (m *Middleware) getMethodConfig(method string) *MethodConfig {
	m.mu.RLock()
	if config, ok := m.methodCache[method]; ok {
		m.mu.RUnlock()
		return config
	}
	m.mu.RUnlock()

	config := &MethodConfig{
		Role: domain.UserRoleUser,
	}

	parts := strings.Split(method, "/")
	if len(parts) < 3 {
		m.cacheMethodConfig(method, config)
		return config
	}

	serviceName := parts[1]
	desc, err := protoregistry.GlobalFiles.FindDescriptorByName(protoreflect.FullName(serviceName))
	if err != nil {
		m.cacheMethodConfig(method, config)
		return config
	}

	if serviceDesc, ok := desc.(protoreflect.ServiceDescriptor); ok {
		methodName := parts[2]
		methodDesc := serviceDesc.Methods().ByName(protoreflect.Name(methodName))
		if methodDesc != nil {
			opts := methodDesc.Options()
			if opts != nil {
				if ext := proto.GetExtension(opts, commonpb.E_MethodConf); ext != nil {
					if methodConf, ok := ext.(*commonpb.MethodConf); ok && methodConf != nil {
						config.SkipAuth = methodConf.GetSkipAuth()
						config.Role = domain.UserRole(methodConf.GetRole())
					}
				}
			}
		}
	}

	m.cacheMethodConfig(method, config)
	return config
}

func (m *Middleware) cacheMethodConfig(method string, config *MethodConfig) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.methodCache == nil {
		m.methodCache = make(map[string]*MethodConfig)
	}
	m.methodCache[method] = config
}

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
