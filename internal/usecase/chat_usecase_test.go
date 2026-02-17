package usecase

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/magomedcoder/legion/internal/domain"
)

type mockChatRepo struct {
	getById            func(context.Context, int) (*domain.Chat, error)
	getOrCreatePrivate func(context.Context, int, int) (*domain.Chat, error)
	listByUser         func(context.Context, int, int32, int32) ([]*domain.Chat, int32, error)
}

func (m *mockChatRepo) GetById(ctx context.Context, id int) (*domain.Chat, error) {
	if m.getById != nil {
		return m.getById(ctx, id)
	}

	return nil, errors.New("не найдено")
}

func (m *mockChatRepo) GetOrCreatePrivateChat(ctx context.Context, uid, userId int) (*domain.Chat, error) {
	if m.getOrCreatePrivate != nil {
		return m.getOrCreatePrivate(ctx, uid, userId)
	}

	return nil, errors.New("not implemented")
}

func (m *mockChatRepo) ListByUser(ctx context.Context, uid int, page, pageSize int32) ([]*domain.Chat, int32, error) {
	if m.listByUser != nil {
		return m.listByUser(ctx, uid, page, pageSize)
	}

	return nil, 0, nil
}

type mockChatMessageRepo struct {
	create       func(context.Context, *domain.Message) error
	getById      func(context.Context, int64) (*domain.Message, error)
	listByChatId func(context.Context, int, int32, int32) ([]*domain.Message, int32, error)
}

func (m *mockChatMessageRepo) Create(ctx context.Context, msg *domain.Message) error {
	if m.create != nil {
		return m.create(ctx, msg)
	}

	return nil
}

func (m *mockChatMessageRepo) GetById(ctx context.Context, id int64) (*domain.Message, error) {
	if m.getById != nil {
		return m.getById(ctx, id)
	}

	return nil, errors.New("не найдено")
}

func (m *mockChatMessageRepo) ListByChatId(ctx context.Context, chatId int, page, pageSize int32) ([]*domain.Message, int32, error) {
	if m.listByChatId != nil {
		return m.listByChatId(ctx, chatId, page, pageSize)
	}

	return nil, 0, nil
}

func (m *mockChatRepo) GetAllUserIds(ctx context.Context, uid int) []int64 {
	return nil
}

type mockUserRepoForChat struct {
	getById func(context.Context, int) (*domain.User, error)
}

func (m *mockUserRepoForChat) GetById(ctx context.Context, id int) (*domain.User, error) {
	if m.getById != nil {
		return m.getById(ctx, id)
	}

	return nil, errors.New("не найдено")
}

func (m *mockUserRepoForChat) Create(context.Context, *domain.User) error {
	return nil
}

func (m *mockUserRepoForChat) GetByUsername(context.Context, string) (*domain.User, error) {
	return nil, nil
}

func (m *mockUserRepoForChat) List(context.Context, int32, int32) ([]*domain.User, int32, error) {
	return nil, 0, nil
}

func (m *mockUserRepoForChat) Search(context.Context, string, int32, int32) ([]*domain.User, int32, error) {
	return nil, 0, nil
}

func (m *mockUserRepoForChat) Update(context.Context, *domain.User) error {
	return nil
}

func (m *mockUserRepoForChat) UpdateLastVisitedAt(context.Context, int) error {
	return nil
}

func TestChatUseCase_CreateChat_success(t *testing.T) {
	chat := &domain.Chat{
		Id:         1,
		UserId:     1,
		ReceiverId: 2,
		CreatedAt:  time.Now(),
	}
	user := &domain.User{
		Id:       2,
		Username: "u2",
		Name:     "U2",
		Surname:  "S2",
		Role:     domain.UserRoleUser,
	}
	chatRepo := &mockChatRepo{
		getOrCreatePrivate: func(context.Context, int, int) (*domain.Chat, error) {
			return chat, nil
		},
	}
	userRepo := &mockUserRepoForChat{
		getById: func(context.Context, int) (*domain.User, error) {
			return user, nil
		},
	}
	uc := NewChatUseCase(chatRepo, &mockChatMessageRepo{}, userRepo)
	ctx := context.Background()

	gotChat, gotUser, err := uc.CreateChat(ctx, 1, 2)
	if err != nil {
		t.Fatalf("CreateChat: %v", err)
	}
	if gotChat != chat || gotUser != user {
		t.Errorf("ожидались chat=%v user=%v", chat, user)
	}
}

func TestChatUseCase_CreateChat_getOrCreateError(t *testing.T) {
	chatRepo := &mockChatRepo{
		getOrCreatePrivate: func(context.Context, int, int) (*domain.Chat, error) {
			return nil, errors.New("db error")
		},
	}
	uc := NewChatUseCase(chatRepo, &mockChatMessageRepo{}, &mockUserRepoForChat{})
	ctx := context.Background()

	_, _, err := uc.CreateChat(ctx, 1, 2)
	if err == nil {
		t.Fatal("ожидалась ошибка")
	}

	if err.Error() != "db error" {
		t.Errorf("получено %q", err.Error())
	}
}

func TestChatUseCase_GetChats_success(t *testing.T) {
	chats := []*domain.Chat{
		{
			Id:         1,
			UserId:     1,
			ReceiverId: 2,
		},
	}
	user := &domain.User{
		Id:       2,
		Username: "u2",
		Role:     domain.UserRoleUser,
	}
	chatRepo := &mockChatRepo{
		listByUser: func(context.Context, int, int32, int32) ([]*domain.Chat, int32, error) {
			return chats, 1, nil
		},
	}
	userRepo := &mockUserRepoForChat{
		getById: func(context.Context, int) (*domain.User, error) {
			return user, nil
		},
	}
	uc := NewChatUseCase(chatRepo, &mockChatMessageRepo{}, userRepo)
	ctx := context.Background()

	gotChats, usersMap, total, err := uc.GetChats(ctx, 1, 0, 10)
	if err != nil {
		t.Fatalf("GetChats: %v", err)
	}

	if total != 1 || len(gotChats) != 1 || gotChats[0].Id != 1 {
		t.Errorf("ожидался 1 чат, получено total=%d len=%d", total, len(gotChats))
	}

	if usersMap[2] == nil || usersMap[2].Username != "u2" {
		t.Errorf("ожидался user 2 в usersMap, получено %v", usersMap)
	}
}

func TestChatUseCase_SendMessage_success(t *testing.T) {
	chat := &domain.Chat{
		Id:         1,
		UserId:     1,
		ReceiverId: 2,
	}
	var createdMsg *domain.Message
	chatRepo := &mockChatRepo{
		getById: func(context.Context, int) (*domain.Chat, error) {
			return chat, nil
		},
	}
	msgRepo := &mockChatMessageRepo{
		create: func(ctx context.Context, msg *domain.Message) error {
			createdMsg = msg
			msg.Id = 100
			return nil
		},
	}
	uc := NewChatUseCase(chatRepo, msgRepo, &mockUserRepoForChat{})
	ctx := context.Background()

	msg, err := uc.SendMessage(ctx, 1, 1, "hello")
	if err != nil {
		t.Fatalf("SendMessage: %v", err)
	}

	if createdMsg == nil || createdMsg.Content != "hello" || createdMsg.ChatId != 1 || createdMsg.UserId != 1 || createdMsg.ReceiverId != 2 {
		t.Errorf("ожидалось сообщение hello в чат 1 от 1 к 2, получено %v", createdMsg)
	}

	if msg.Id != 100 {
		t.Errorf("ожидался msg.Id=100, получено %d", msg.Id)
	}
}

func TestChatUseCase_SendMessage_unauthorized(t *testing.T) {
	chat := &domain.Chat{
		Id:         1,
		UserId:     10,
		ReceiverId: 20,
	}
	chatRepo := &mockChatRepo{
		getById: func(context.Context, int) (*domain.Chat, error) {
			return chat, nil
		},
	}
	uc := NewChatUseCase(chatRepo, &mockChatMessageRepo{}, &mockUserRepoForChat{})
	ctx := context.Background()

	_, err := uc.SendMessage(ctx, 1, 1, "hello")
	if err == nil {
		t.Fatal("ожидалась ошибка ErrUnauthorized")
	}
	if err != domain.ErrUnauthorized {
		t.Errorf("ожидался domain.ErrUnauthorized, получено %v", err)
	}
}

func TestChatUseCase_GetMessages_unauthorized(t *testing.T) {
	chat := &domain.Chat{
		Id:         1,
		UserId:     10,
		ReceiverId: 20,
	}
	chatRepo := &mockChatRepo{
		getById: func(context.Context, int) (*domain.Chat, error) {
			return chat, nil
		},
	}
	uc := NewChatUseCase(chatRepo, &mockChatMessageRepo{}, &mockUserRepoForChat{})
	ctx := context.Background()

	_, _, err := uc.GetMessages(ctx, 1, 1, 0, 10)
	if err != domain.ErrUnauthorized {
		t.Errorf("ожидался ErrUnauthorized, получено %v", err)
	}
}

func TestChatUseCase_GetMessages_success(t *testing.T) {
	chat := &domain.Chat{
		Id:         1,
		UserId:     1,
		ReceiverId: 2,
	}
	msgs := []*domain.Message{
		{
			Id:      1,
			ChatId:  1,
			UserId:  1,
			Content: "hi",
		},
	}
	chatRepo := &mockChatRepo{
		getById: func(context.Context, int) (*domain.Chat, error) {
			return chat, nil
		},
	}
	msgRepo := &mockChatMessageRepo{
		listByChatId: func(context.Context, int, int32, int32) ([]*domain.Message, int32, error) {
			return msgs, 1, nil
		},
	}
	uc := NewChatUseCase(chatRepo, msgRepo, &mockUserRepoForChat{})
	ctx := context.Background()

	got, total, err := uc.GetMessages(ctx, 1, 1, 0, 10)
	if err != nil {
		t.Fatalf("GetMessages: %v", err)
	}

	if total != 1 || len(got) != 1 || got[0].Content != "hi" {
		t.Errorf("ожидался 1 сообщение hi, получено total=%d len=%d", total, len(got))
	}
}
