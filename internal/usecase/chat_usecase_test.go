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
	getPrivateChat     func(context.Context, int, int) (*domain.Chat, error)
	getOrCreatePrivate func(context.Context, int, int) (*domain.Chat, error)
	listByUser         func(context.Context, int) ([]*domain.Chat, error)
}

func (m *mockChatRepo) GetById(ctx context.Context, id int) (*domain.Chat, error) {
	if m.getById != nil {
		return m.getById(ctx, id)
	}

	return nil, errors.New("не найдено")
}

func (m *mockChatRepo) GetPrivateChat(ctx context.Context, uid, userId int) (*domain.Chat, error) {
	if m.getPrivateChat != nil {
		return m.getPrivateChat(ctx, uid, userId)
	}
	
	return nil, errors.New("не найдено")
}

func (m *mockChatRepo) GetOrCreatePrivateChat(ctx context.Context, uid, userId int) (*domain.Chat, error) {
	if m.getOrCreatePrivate != nil {
		return m.getOrCreatePrivate(ctx, uid, userId)
	}

	return nil, errors.New("not implemented")
}

func (m *mockChatRepo) ListByUser(ctx context.Context, uid int) ([]*domain.Chat, error) {
	if m.listByUser != nil {
		return m.listByUser(ctx, uid)
	}

	return nil, nil
}

func (m *mockChatRepo) EnsurePeerChat(ctx context.Context, uid, peerUserId int) error {
	return nil
}

type mockChatMessageRepo struct {
	create     func(context.Context, *domain.Message) error
	getById    func(context.Context, int64) (*domain.Message, error)
	getHistory func(context.Context, int, int, int64, int) ([]*domain.Message, error)
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

func (m *mockChatMessageRepo) GetHistory(ctx context.Context, peerId1, peerId2 int, messageId int64, limit int) ([]*domain.Message, error) {
	if m.getHistory != nil {
		return m.getHistory(ctx, peerId1, peerId2, messageId, limit)
	}
	return nil, nil
}

func (m *mockChatMessageRepo) Delete(ctx context.Context, id int64) error {
	return nil
}

type mockUserDeletedMessageRepo struct {
	add                 func(context.Context, int, []int64) error
	getDeletedMessageIds func(context.Context, int, []int64) ([]int64, error)
}

func (m *mockUserDeletedMessageRepo) Add(ctx context.Context, userID int, messageIDs []int64) error {
	if m.add != nil {
		return m.add(ctx, userID, messageIDs)
	}
	
	return nil
}

func (m *mockUserDeletedMessageRepo) GetDeletedMessageIds(ctx context.Context, userID int, messageIDs []int64) ([]int64, error) {
	if m.getDeletedMessageIds != nil {
		return m.getDeletedMessageIds(ctx, userID, messageIDs)
	}

	return nil, nil
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
		Id:        1,
		UserId:    1,
		PeerId:    2,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
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
	uc := NewChatUseCase(chatRepo, &mockChatMessageRepo{}, &mockUserDeletedMessageRepo{}, userRepo)
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
	uc := NewChatUseCase(chatRepo, &mockChatMessageRepo{}, &mockUserDeletedMessageRepo{}, &mockUserRepoForChat{})
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
			Id:        1,
			UserId:    1,
			PeerId:    2,
		},
	}
	user := &domain.User{
		Id:       2,
		Username: "u2",
		Role:     domain.UserRoleUser,
	}
	chatRepo := &mockChatRepo{
		listByUser: func(context.Context, int) ([]*domain.Chat, error) {
			return chats, nil
		},
	}
	userRepo := &mockUserRepoForChat{
		getById: func(context.Context, int) (*domain.User, error) {
			return user, nil
		},
	}
	uc := NewChatUseCase(chatRepo, &mockChatMessageRepo{}, &mockUserDeletedMessageRepo{}, userRepo)
	ctx := context.Background()

	gotChats, users, err := uc.GetChats(ctx, 1)
	if err != nil {
		t.Fatalf("GetChats: %v", err)
	}

	if len(gotChats) != 1 || gotChats[0].Id != 1 {
		t.Errorf("ожидался 1 чат, получено len=%d", len(gotChats))
	}

	if len(users) != 1 || users[0].Username != "u2" {
		t.Errorf("ожидался user 2 в users, получено %v", users)
	}
}

func TestChatUseCase_SendMessage_success(t *testing.T) {
	chat := &domain.Chat{
		Id:     1,
		UserId: 1,
		PeerId: 2,
	}
	var createdMsg *domain.Message
	chatRepo := &mockChatRepo{
		getPrivateChat: func(context.Context, int, int) (*domain.Chat, error) {
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
	uc := NewChatUseCase(chatRepo, msgRepo, &mockUserDeletedMessageRepo{}, &mockUserRepoForChat{})
	ctx := context.Background()

	msg, err := uc.SendMessage(ctx, 1, 2, "hello")
	if err != nil {
		t.Fatalf("SendMessage: %v", err)
	}

	if createdMsg == nil || createdMsg.Content != "hello" || createdMsg.PeerId != 2 || createdMsg.FromPeerId != 1 {
		t.Errorf("ожидалось сообщение hello от 1 к 2, получено %v", createdMsg)
	}

	if msg.Id != 100 {
		t.Errorf("ожидался msg.Id=100, получено %d", msg.Id)
	}
}

func TestChatUseCase_SendMessage_noChat_returnsError(t *testing.T) {
	chatRepo := &mockChatRepo{
		getPrivateChat: func(context.Context, int, int) (*domain.Chat, error) {
			return nil, errors.New("чат не найден")
		},
	}
	uc := NewChatUseCase(chatRepo, &mockChatMessageRepo{}, &mockUserDeletedMessageRepo{}, &mockUserRepoForChat{})
	ctx := context.Background()

	_, err := uc.SendMessage(ctx, 1, 5, "hello")
	if err == nil {
		t.Fatal("ожидалась ошибка")
	}
}

func TestChatUseCase_GetHistory_unauthorized(t *testing.T) {
	chat := &domain.Chat{
		Id:     1,
		UserId: 10,
		PeerId: 20,
	}
	chatRepo := &mockChatRepo{
		getPrivateChat: func(context.Context, int, int) (*domain.Chat, error) {
			return chat, nil
		},
	}
	uc := NewChatUseCase(chatRepo, &mockChatMessageRepo{}, &mockUserDeletedMessageRepo{}, &mockUserRepoForChat{})
	ctx := context.Background()

	_, _, err := uc.GetHistory(ctx, 1, 2, 0, 10)
	if err != domain.ErrUnauthorized {
		t.Errorf("ожидался ErrUnauthorized, получено %v", err)
	}
}

func TestChatUseCase_GetHistory_success(t *testing.T) {
	chat := &domain.Chat{
		Id:     1,
		UserId: 1,
		PeerId: 2,
	}
	msgs := []*domain.Message{
		{
			Id:           1,
			PeerId:       2,
			FromPeerId:   1,
			Content:      "hi",
		},
	}
	user := &domain.User{Id: 1, Username: "u1"}
	chatRepo := &mockChatRepo{
		getPrivateChat: func(context.Context, int, int) (*domain.Chat, error) {
			return chat, nil
		},
	}
	msgRepo := &mockChatMessageRepo{
		getHistory: func(context.Context, int, int, int64, int) ([]*domain.Message, error) {
			return msgs, nil
		},
	}
	userRepo := &mockUserRepoForChat{
		getById: func(context.Context, int) (*domain.User, error) {
			return user, nil
		},
	}
	uc := NewChatUseCase(chatRepo, msgRepo, &mockUserDeletedMessageRepo{}, userRepo)
	ctx := context.Background()

	gotMsgs, gotUsers, err := uc.GetHistory(ctx, 1, 2, 0, 10)
	if err != nil {
		t.Fatalf("GetHistory: %v", err)
	}

	if len(gotMsgs) != 1 || gotMsgs[0].Content != "hi" {
		t.Errorf("ожидалось 1 сообщение hi, получено len=%d", len(gotMsgs))
	}
	if len(gotUsers) == 0 {
		t.Error("ожидались пользователи в ответе")
	}
}
