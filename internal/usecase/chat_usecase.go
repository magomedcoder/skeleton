package usecase

import (
	"context"
	"fmt"
	"strconv"

	"github.com/magomedcoder/legion/internal/domain"
	redisRepo "github.com/magomedcoder/legion/internal/repository/redis_repository"
	"github.com/magomedcoder/legion/pkg/jsonutil"
	"github.com/redis/go-redis/v9"
)

type ChatUseCase struct {
	chatRepo       domain.ChatRepository
	messageRepo    domain.ChatMessageRepository
	userRepository domain.UserRepository
	redis          *redis.Client
	serverCache    *redisRepo.ServerCacheRepository
	clientCache    *redisRepo.ClientCacheRepository
}

func NewChatUseCase(
	chatRepo domain.ChatRepository,
	messageRepo domain.ChatMessageRepository,
	userRepo domain.UserRepository,
	opts ...ChatUseCaseOption,
) *ChatUseCase {
	c := &ChatUseCase{
		chatRepo:       chatRepo,
		messageRepo:    messageRepo,
		userRepository: userRepo,
	}

	for _, opt := range opts {
		opt(c)
	}

	return c
}

type ChatUseCaseOption func(*ChatUseCase)

func WithChatRedis(rds *redis.Client) ChatUseCaseOption {
	return func(c *ChatUseCase) { c.redis = rds }
}

func WithChatServerCache(s *redisRepo.ServerCacheRepository) ChatUseCaseOption {
	return func(c *ChatUseCase) { c.serverCache = s }
}

func WithChatClientCache(cl *redisRepo.ClientCacheRepository) ChatUseCaseOption {
	return func(c *ChatUseCase) { c.clientCache = cl }
}

func (c *ChatUseCase) verifyChatOwnership(ctx context.Context, userId, chatId int) (*domain.Chat, error) {
	chat, err := c.chatRepo.GetById(ctx, chatId)
	if err != nil {
		return nil, err
	}

	if chat.UserId != userId && chat.ReceiverId != userId {
		return nil, domain.ErrUnauthorized
	}

	return chat, nil
}

func (c *ChatUseCase) CreateChat(ctx context.Context, uid int, userId int) (*domain.Chat, *domain.User, error) {
	chat, err := c.chatRepo.GetOrCreatePrivateChat(ctx, uid, userId)
	if err != nil {
		return nil, nil, err
	}

	chatUserId := userId
	if chat.UserId == uid {
		chatUserId = chat.ReceiverId
	} else {
		chatUserId = chat.UserId
	}

	user, err := c.userRepository.GetById(ctx, chatUserId)
	if err != nil {
		return nil, nil, err
	}

	return chat, user, nil
}

func (c *ChatUseCase) GetChats(ctx context.Context, uid int, page, pageSize int32) ([]*domain.Chat, map[int]*domain.User, int32, error) {
	chats, total, err := c.chatRepo.ListByUser(ctx, uid, page, pageSize)
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

		u, err := c.userRepository.GetById(ctx, userId)
		if err != nil {
			continue
		}
		usersMap[userId] = u
	}

	return chats, usersMap, total, nil
}

func (c *ChatUseCase) SendMessage(ctx context.Context, uid int, chatId int, content string) (*domain.Message, error) {
	chat, err := c.verifyChatOwnership(ctx, uid, chatId)
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

	if err := c.messageRepo.Create(ctx, msg); err != nil {
		return nil, err
	}

	_ = c.PublishNewMessage(ctx, msg)

	return msg, nil
}

func (c *ChatUseCase) PublishNewMessage(ctx context.Context, msg *domain.Message) error {
	if c.redis == nil || c.serverCache == nil || c.clientCache == nil {
		return nil
	}

	dataStr := jsonutil.Encode(map[string]any{
		"senderId":  msg.UserId,
		"toId":      msg.ReceiverId,
		"chatType":  msg.ChatType,
		"messageId": msg.Id,
	})
	content := jsonutil.Encode(map[string]any{
		"event": domain.SubEventNewMessage,
		"data":  dataStr,
	})

	sids := c.serverCache.All(ctx, 1)
	if len(sids) == 0 {
		return nil
	}

	pipe := c.redis.Pipeline()
	for _, sid := range sids {
		senderOnline := c.clientCache.IsCurrentServerOnline(ctx, sid, domain.ChatChannelName, strconv.Itoa(msg.UserId))
		receiverOnline := c.clientCache.IsCurrentServerOnline(ctx, sid, domain.ChatChannelName, strconv.Itoa(msg.ReceiverId))
		if senderOnline || receiverOnline {
			pipe.Publish(ctx, fmt.Sprintf(domain.LegionTopicByServer, sid), content)
		}
	}

	_, err := pipe.Exec(ctx)

	return err
}

func (c *ChatUseCase) GetMessageById(ctx context.Context, messageId int64) (*domain.Message, error) {
	return c.messageRepo.GetById(ctx, messageId)
}

func (c *ChatUseCase) GetMessages(ctx context.Context, uid int, chatId int, page, pageSize int32) ([]*domain.Message, int32, error) {
	if _, err := c.verifyChatOwnership(ctx, uid, chatId); err != nil {
		return nil, 0, err
	}

	return c.messageRepo.ListByChatId(ctx, chatId, page, pageSize)
}

func (c *ChatUseCase) GetAllUserIds(ctx context.Context, uid int) []int64 {
	return c.chatRepo.GetAllUserIds(ctx, uid)
}
