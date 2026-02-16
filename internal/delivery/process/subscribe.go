package process

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/magomedcoder/legion/internal/config"
	"github.com/magomedcoder/legion/internal/delivery/consume"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/domain/event"
	"github.com/magomedcoder/legion/pkg"
	"github.com/redis/go-redis/v9"
	"github.com/sourcegraph/conc/pool"
)

type MessageSubscriber struct {
	Conf    *config.Config
	Redis   *redis.Client
	Consume *consume.ChatSubscribe
}

func NewMessageSubscriber(
	conf *config.Config,
	redis *redis.Client,
	consume *consume.ChatSubscribe,
) *MessageSubscriber {
	return &MessageSubscriber{
		Conf:    conf,
		Redis:   redis,
		Consume: consume,
	}
}

type EventConsumer interface {
	Call(event string, data []byte)
}

func (m *MessageSubscriber) Setup(ctx context.Context) error {
	go m.run(ctx)
	<-ctx.Done()
	return nil
}

func (m *MessageSubscriber) run(ctx context.Context) {
	topics := []string{
		domain.LegionTopicAll,
		fmt.Sprintf(domain.LegionTopicByServer, m.Conf.ServerId()),
	}
	sub := m.Redis.Subscribe(ctx, topics...)
	defer sub.Close()

	worker := pool.New().WithMaxGoroutines(10)
	ch := sub.Channel()

	for {
		select {
		case <-ctx.Done():
			return
		case msg, ok := <-ch:
			if !ok {
				return
			}
			m.dispatch(worker, msg)
		}
	}
}

func (m *MessageSubscriber) dispatch(worker *pool.Pool, msg *redis.Message) {
	worker.Go(func() {
		defer func() {
			if err := recover(); err != nil {
				log.Printf("Ошибка при вызове обработчика уведомления: %s", pkg.PanicTrace(err))
			}
		}()

		var in event.SubscribeContent
		if err := json.Unmarshal([]byte(msg.Payload), &in); err != nil {
			log.Printf("Ошибка разбора содержимого подписки: %s", err)
			return
		}
		m.Consume.Call(in.Event, []byte(in.Data))
	})
}
