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

	if chat.UserId != userId && chat.PeerId != userId {
		return nil, domain.ErrUnauthorized
	}

	return chat, nil
}

func (c *ChatUseCase) CreateChat(ctx context.Context, uid int, userId int) (*domain.Chat, *domain.User, error) {
	chat, err := c.chatRepo.GetOrCreatePrivateChat(ctx, uid, userId)
	if err != nil {
		return nil, nil, err
	}

	user, err := c.userRepository.GetById(ctx, chat.PeerId)
	if err != nil {
		return nil, nil, err
	}

	return chat, user, nil
}

func (c *ChatUseCase) GetChats(ctx context.Context, uid int) ([]*domain.Chat, []*domain.User, error) {
	chats, err := c.chatRepo.ListByUser(ctx, uid)
	if err != nil {
		return nil, nil, err
	}

	seen := make(map[int]struct{})
	users := make([]*domain.User, 0)
	for _, ch := range chats {
		if _, ok := seen[ch.PeerId]; ok {
			continue
		}
		seen[ch.PeerId] = struct{}{}
		u, err := c.userRepository.GetById(ctx, ch.PeerId)
		if err != nil {
			continue
		}
		users = append(users, u)
	}

	return chats, users, nil
}

const PeerTypeUser = 1

func (c *ChatUseCase) SendMessage(ctx context.Context, uid int, peerUserId int, content string) (*domain.Message, error) {
	_, err := c.chatRepo.GetPrivateChat(ctx, uid, peerUserId)
	if err != nil {
		return nil, err
	}

	if err := c.chatRepo.EnsurePeerChat(ctx, uid, peerUserId); err != nil {
		return nil, err
	}

	msg := &domain.Message{
		PeerType:     PeerTypeUser,
		PeerId:       peerUserId,
		FromPeerType: PeerTypeUser,
		FromPeerId:   uid,
		Content:      content,
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
		"peerType":   PeerTypeUser,
		"peerId":     msg.PeerId,
		"fromPeerId": msg.FromPeerId,
		"messageId":  msg.Id,
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
		senderOnline := c.clientCache.IsCurrentServerOnline(ctx, sid, domain.ChatChannelName, strconv.Itoa(msg.FromPeerId))
		receiverOnline := c.clientCache.IsCurrentServerOnline(ctx, sid, domain.ChatChannelName, strconv.Itoa(msg.PeerId))
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

func (c *ChatUseCase) GetHistory(ctx context.Context, uid int, peerUserId int64, messageId int64, limit int64) ([]*domain.Message, []*domain.User, error) {
	peerId := int(peerUserId)
	chat, err := c.chatRepo.GetPrivateChat(ctx, uid, peerId)
	if err != nil {
		return nil, nil, nil
	}

	if chat.UserId != uid {
		return nil, nil, domain.ErrUnauthorized
	}

	if limit <= 0 || limit > 100 {
		limit = 50
	}

	msgs, err := c.messageRepo.GetHistory(ctx, uid, peerId, messageId, int(limit))
	if err != nil {
		return nil, nil, err
	}

	userIds := make(map[int]struct{})
	userIds[peerId] = struct{}{}
	for _, m := range msgs {
		userIds[m.PeerId] = struct{}{}
		userIds[m.FromPeerId] = struct{}{}
	}

	users := make([]*domain.User, 0, len(userIds))
	for id := range userIds {
		u, err := c.userRepository.GetById(ctx, id)
		if err != nil {
			continue
		}
		users = append(users, u)
	}

	return msgs, users, nil
}

func (c *ChatUseCase) GetAllUserIds(ctx context.Context, uid int) []int64 {
	return c.chatRepo.GetAllUserIds(ctx, uid)
}
