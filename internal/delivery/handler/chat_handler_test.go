package handler

import (
	"context"
	"testing"

	"github.com/magomedcoder/legion/api/pb/chatpb"
	"github.com/magomedcoder/legion/api/pb/commonpb"
	"github.com/magomedcoder/legion/internal/delivery/middleware"
	"github.com/magomedcoder/legion/internal/usecase"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const sessionKey = "__LEGION_SESSION__"

func ctxWithSession(uid int) context.Context {
	return context.WithValue(context.Background(), sessionKey, &middleware.JSession{Uid: uid})
}

func TestChatHandler_CreateChat_noSession_returnsUnauthenticated(t *testing.T) {
	h := NewChatHandler(&usecase.ChatUseCase{}, nil)
	ctx := context.Background()

	_, err := h.CreateChat(ctx, &chatpb.CreateChatRequest{
		UserId: "1",
	})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("CreateChat(без сессии): код %v, ожидался Unauthenticated", code)
	}
}

func TestChatHandler_CreateChat_invalidUserId_returnsInvalidArgument(t *testing.T) {
	h := NewChatHandler(&usecase.ChatUseCase{}, nil)
	ctx := ctxWithSession(1)

	_, err := h.CreateChat(ctx, &chatpb.CreateChatRequest{
		UserId: "not-a-number",
	})
	if code := status.Code(err); code != codes.InvalidArgument {
		t.Errorf("CreateChat(неверный userId): код %v, ожидался InvalidArgument", code)
	}
}

func TestChatHandler_GetChats_noSession_returnsUnauthenticated(t *testing.T) {
	h := NewChatHandler(&usecase.ChatUseCase{}, nil)
	ctx := context.Background()

	_, err := h.GetChats(ctx, &chatpb.GetChatsRequest{})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("GetChats(без сессии): код %v, ожидался Unauthenticated", code)
	}
}

func TestChatHandler_SendMessage_noSession_returnsUnauthenticated(t *testing.T) {
	h := NewChatHandler(&usecase.ChatUseCase{}, nil)
	ctx := context.Background()

	_, err := h.SendMessage(ctx, &chatpb.SendMessageRequest{
		Peer:    &commonpb.Peer{Peer: &commonpb.Peer_UserId{UserId: 2}},
		Content: "hi",
	})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("SendMessage(без сессии): код %v, ожидался Unauthenticated", code)
	}
}

func TestChatHandler_SendMessage_noPeer_returnsInvalidArgument(t *testing.T) {
	h := NewChatHandler(&usecase.ChatUseCase{}, nil)
	ctx := ctxWithSession(1)

	_, err := h.SendMessage(ctx, &chatpb.SendMessageRequest{
		Content: "hi",
	})
	if code := status.Code(err); code != codes.InvalidArgument {
		t.Errorf("SendMessage(без peer): код %v, ожидался InvalidArgument", code)
	}
}

func TestChatHandler_GetHistory_noSession_returnsUnauthenticated(t *testing.T) {
	h := NewChatHandler(&usecase.ChatUseCase{}, nil)
	ctx := context.Background()

	_, err := h.GetHistory(ctx, &chatpb.GetHistoryRequest{
		Peer: &commonpb.Peer{Peer: &commonpb.Peer_UserId{UserId: 2}},
	})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("GetHistory(без сессии): код %v, ожидался Unauthenticated", code)
	}
}

func TestChatHandler_GetHistory_noPeer_returnsInvalidArgument(t *testing.T) {
	h := NewChatHandler(&usecase.ChatUseCase{}, nil)
	ctx := ctxWithSession(1)

	_, err := h.GetHistory(ctx, &chatpb.GetHistoryRequest{})
	if code := status.Code(err); code != codes.InvalidArgument {
		t.Errorf("GetHistory(без peer): код %v, ожидался InvalidArgument", code)
	}
}
