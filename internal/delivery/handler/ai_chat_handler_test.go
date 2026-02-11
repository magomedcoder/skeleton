package handler

import (
	"context"
	"github.com/magomedcoder/legion/internal/usecase"
	"testing"

	"github.com/magomedcoder/legion/api/pb/aichatpb"
	"github.com/magomedcoder/legion/api/pb/commonpb"
	"github.com/magomedcoder/legion/internal/domain"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

var _ usecase.TokenValidator = (*fakeAuth)(nil)

type fakeAuth struct {
	user *domain.User
	err  error
}

func (f *fakeAuth) ValidateToken(_ context.Context, _ string) (*domain.User, error) {
	if f.err != nil {
		return nil, f.err
	}

	return f.user, nil
}

func TestAIChatHandler_CheckConnection(t *testing.T) {
	h := NewAIChatHandler(nil, nil)
	ctx := context.Background()

	resp, err := h.CheckConnection(ctx, &commonpb.Empty{})
	if err != nil {
		t.Fatalf("CheckConnection: %v", err)
	}

	if !resp.IsConnected {
		t.Error("ожидалось IsConnected=true")
	}
}

func TestAIChatHandler_CreateSession_noAuth(t *testing.T) {
	h := NewAIChatHandler(nil, nil)
	ctx := context.Background()

	_, err := h.CreateSession(ctx, &aichatpb.CreateSessionRequest{
		Title: "test",
	})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("CreateSession: код %v, ожидался Unauthenticated", code)
	}
}

func TestAIChatHandler_GetSession_noAuth(t *testing.T) {
	h := NewAIChatHandler(nil, nil)
	ctx := context.Background()

	_, err := h.GetSession(ctx, &aichatpb.GetSessionRequest{
		SessionId: "id",
	})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("GetSession: код %v, ожидался Unauthenticated", code)
	}
}

func TestAIChatHandler_GetSessions_noAuth(t *testing.T) {
	h := NewAIChatHandler(nil, nil)
	ctx := context.Background()

	_, err := h.GetSessions(ctx, &aichatpb.GetSessionsRequest{})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("GetSessions: код %v, ожидался Unauthenticated", code)
	}
}

func TestAIChatHandler_GetSessionMessages_noAuth(t *testing.T) {
	h := NewAIChatHandler(nil, nil)
	ctx := context.Background()

	_, err := h.GetSessionMessages(ctx, &aichatpb.GetSessionMessagesRequest{
		SessionId: "id",
	})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("GetSessionMessages: код %v, ожидался Unauthenticated", code)
	}
}

func TestAIChatHandler_DeleteSession_noAuth(t *testing.T) {
	h := NewAIChatHandler(nil, nil)
	ctx := context.Background()

	_, err := h.DeleteSession(ctx, &aichatpb.DeleteSessionRequest{
		SessionId: "id",
	})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("DeleteSession: код %v, ожидался Unauthenticated", code)
	}
}

func TestAIChatHandler_UpdateSessionTitle_noAuth(t *testing.T) {
	h := NewAIChatHandler(nil, nil)
	ctx := context.Background()

	_, err := h.UpdateSessionTitle(ctx, &aichatpb.UpdateSessionTitleRequest{
		SessionId: "id",
		Title:     "t",
	})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("UpdateSessionTitle: код %v, ожидался Unauthenticated", code)
	}
}

func TestAIChatHandler_UpdateSessionModel_noAuth(t *testing.T) {
	h := NewAIChatHandler(nil, nil)
	ctx := context.Background()

	_, err := h.UpdateSessionModel(ctx, &aichatpb.UpdateSessionModelRequest{
		SessionId: "id",
	})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("UpdateSessionModel: код %v, ожидался Unauthenticated", code)
	}
}
