package handler

import (
	"errors"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestToStatusError(t *testing.T) {
	tests := []struct {
		code     codes.Code
		err      error
		wantCode codes.Code
		wantMsg  string
	}{
		{codes.Internal, nil, codes.Internal, "внутренняя ошибка сервера"},
		{codes.Unauthenticated, nil, codes.Unauthenticated, "неверные учётные данные"},
		{codes.NotFound, nil, codes.NotFound, "не найдено"},
		{codes.InvalidArgument, nil, codes.InvalidArgument, "неверный запрос"},
		{codes.PermissionDenied, nil, codes.PermissionDenied, "доступ запрещён"},
		{codes.Unavailable, nil, codes.Unavailable, "сервис временно недоступен"},
		{codes.Unknown, nil, codes.Unknown, "произошла ошибка"},
	}
	for _, tt := range tests {
		got := ToStatusError(tt.code, tt.err)
		if got == nil {
			t.Errorf("ToStatusError(%v, %v) вернул nil", tt.code, tt.err)
			continue
		}

		st, ok := status.FromError(got)
		if !ok {
			t.Errorf("ToStatusError: не gRPC status")
			continue
		}

		if st.Code() != tt.wantCode {
			t.Errorf("код: получено %v, ожидалось %v", st.Code(), tt.wantCode)
		}

		if st.Message() != tt.wantMsg {
			t.Errorf("сообщение: получено %q, ожидалось %q", st.Message(), tt.wantMsg)
		}
	}
}

func TestToStatusError_withErr(t *testing.T) {
	someErr := errors.New("исходная ошибка")
	got := ToStatusError(codes.Internal, someErr)
	if got == nil {
		t.Fatal("ожидалась непустая ошибка")
	}

	st, _ := status.FromError(got)
	if st.Code() != codes.Internal {
		t.Errorf("код: %v", st.Code())
	}
}
