package handler

import (
	"context"
	"github.com/magomedcoder/legion/internal/delivery/middleware"
	"testing"

	"github.com/magomedcoder/legion/api/pb/chatpb"
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
		ChatId:  "1",
		Content: "hi",
	})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("SendMessage(без сессии): код %v, ожидался Unauthenticated", code)
	}
}

func TestChatHandler_SendMessage_emptyChatId_returnsInvalidArgument(t *testing.T) {
	h := NewChatHandler(&usecase.ChatUseCase{}, nil)
	ctx := ctxWithSession(1)

	_, err := h.SendMessage(ctx, &chatpb.SendMessageRequest{
		ChatId:  "",
		Content: "hi",
	})
	if code := status.Code(err); code != codes.InvalidArgument {
		t.Errorf("SendMessage(пустой chatId): код %v, ожидался InvalidArgument", code)
	}
}

func TestChatHandler_SendMessage_invalidChatId_returnsInvalidArgument(t *testing.T) {
	h := NewChatHandler(&usecase.ChatUseCase{}, nil)
	ctx := ctxWithSession(1)

	_, err := h.SendMessage(ctx, &chatpb.SendMessageRequest{
		ChatId:  "abc",
		Content: "hi",
	})
	if code := status.Code(err); code != codes.InvalidArgument {
		t.Errorf("SendMessage(неверный chatId): код %v, ожидался InvalidArgument", code)
	}
}

func TestChatHandler_GetMessages_noSession_returnsUnauthenticated(t *testing.T) {
	h := NewChatHandler(&usecase.ChatUseCase{}, nil)
	ctx := context.Background()

	_, err := h.GetMessages(ctx, &chatpb.GetMessagesRequest{
		ChatId: "1",
	})
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Errorf("GetMessages(без сессии): код %v, ожидался Unauthenticated", code)
	}
}

func TestChatHandler_GetMessages_invalidChatId_returnsInvalidArgument(t *testing.T) {
	h := NewChatHandler(&usecase.ChatUseCase{}, nil)
	ctx := ctxWithSession(1)

	_, err := h.GetMessages(ctx, &chatpb.GetMessagesRequest{
		ChatId: "x",
	})
	if code := status.Code(err); code != codes.InvalidArgument {
		t.Errorf("GetMessages(неверный chatId): код %v, ожидался InvalidArgument", code)
	}
}
