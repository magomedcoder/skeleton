package handler

import (
	"github.com/magomedcoder/skeleton/pkg/logger"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func ToStatusError(code codes.Code, err error) error {
	msg := safeMessage(code)
	if code == codes.Internal && err != nil {
		logger.E("handler: внутренняя ошибка: %v", err)
	}

	return status.Error(code, msg)
}

func safeMessage(code codes.Code) string {
	switch code {
	case codes.Internal:
		return "внутренняя ошибка сервера"
	case codes.Unauthenticated:
		return "неверные учётные данные"
	case codes.NotFound:
		return "не найдено"
	case codes.InvalidArgument:
		return "неверный запрос"
	case codes.PermissionDenied:
		return "доступ запрещён"
	case codes.Unavailable:
		return "сервис временно недоступен"
	default:
		return "произошла ошибка"
	}
}
