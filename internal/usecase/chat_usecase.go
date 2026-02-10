package usecase

import (
	"context"
	"github.com/magomedcoder/legion/internal/domain"
)

type ChatUseCase struct {
	chatRepo       domain.ChatRepository
	messageRepo    domain.ChatMessageRepository
	userRepository domain.UserRepository
}

func NewChatUseCase(
	chatRepo domain.ChatRepository,
	messageRepo domain.ChatMessageRepository,
	userRepo domain.UserRepository,
) *ChatUseCase {
	return &ChatUseCase{
		chatRepo:       chatRepo,
		messageRepo:    messageRepo,
		userRepository: userRepo,
	}
}

func (uc *ChatUseCase) verifyChatOwnership(ctx context.Context, userId, chatId int) (*domain.Chat, error) {
	chat, err := uc.chatRepo.GetById(ctx, chatId)
	if err != nil {
		return nil, err
	}

	if chat.UserId != userId && chat.ReceiverId != userId {
		return nil, domain.ErrUnauthorized
	}

	return chat, nil
}

func (uc *ChatUseCase) CreateChat(ctx context.Context, uid int, userId int) (*domain.Chat, *domain.User, error) {
	chat, err := uc.chatRepo.GetOrCreatePrivateChat(ctx, uid, userId)
	if err != nil {
		return nil, nil, err
	}

	chatUserId := userId
	if chat.UserId == uid {
		chatUserId = chat.ReceiverId
	} else {
		chatUserId = chat.UserId
	}

	user, err := uc.userRepository.GetById(ctx, chatUserId)
	if err != nil {
		return nil, nil, err
	}

	return chat, user, nil
}

func (uc *ChatUseCase) GetChats(ctx context.Context, uid int, page, pageSize int32) ([]*domain.Chat, map[int]*domain.User, int32, error) {
	chats, total, err := uc.chatRepo.ListByUser(ctx, uid, page, pageSize)
	if err != nil {
		return nil, nil, 0, err
	}

	usersMap := make(map[int]*domain.User)
	for _, ch := range chats {
		var userId int
		if ch.UserId == uid {
			userId = ch.ReceiverId
		} else {
			userId = ch.UserId
		}

		if _, ok := usersMap[userId]; ok {
			continue
		}

		u, err := uc.userRepository.GetById(ctx, userId)
		if err != nil {
			continue
		}
		usersMap[userId] = u
	}

	return chats, usersMap, total, nil
}

func (uc *ChatUseCase) SendMessage(ctx context.Context, uid int, chatId int, content string) (*domain.Message, error) {
	chat, err := uc.verifyChatOwnership(ctx, uid, chatId)
	if err != nil {
		return nil, err
	}

	receiverId := chat.UserId
	if chat.UserId == uid {
		receiverId = chat.ReceiverId
	}

	msg := &domain.Message{
		ChatId:     chatId,
		ChatType:   1,
		UserId:     uid,
		ReceiverId: receiverId,
		Content:    content,
	}

	if err := uc.messageRepo.Create(ctx, msg); err != nil {
		return nil, err
	}

	return msg, nil
}

func (uc *ChatUseCase) GetMessages(ctx context.Context, uid int, chatId int, page, pageSize int32) ([]*domain.Message, int32, error) {
	if _, err := uc.verifyChatOwnership(ctx, uid, chatId); err != nil {
		return nil, 0, err
	}

	return uc.messageRepo.ListByChatId(ctx, chatId, page, pageSize)
}
