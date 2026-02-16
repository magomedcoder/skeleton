package event

import (
	"context"
	"fmt"
	"github.com/magomedcoder/legion/api/pb/accountpb"
	"github.com/magomedcoder/legion/internal/config"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/internal/pkg/socket"
	"github.com/magomedcoder/legion/pkg/jsonutil"
	"github.com/redis/go-redis/v9"
	"google.golang.org/protobuf/proto"
	"log"
)

type ChatEvent struct {
	Redis   *redis.Client
	Conf    *config.Config
	Handler *Handler
}

func (e *ChatEvent) OnOpen(client socket.IClient) {
	fmt.Printf("OnOpen: uid=%v cid=%v канал=%s\n", client.Uid(), client.Cid(), client.Channel().Name())
	ctx := context.Background()

	e.publishUserStatus(ctx, client.Uid(), true)
}

func (e *ChatEvent) publishUserStatus(ctx context.Context, userID int, online bool) {
	if e.Redis == nil {
		return
	}
	payload := jsonutil.Encode(map[string]any{
		"event": domain.SubEventUserStatus,
		"data": jsonutil.Encode(map[string]any{
			"userId": userID,
			"status": online,
		}),
	})
	_ = e.Redis.Publish(ctx, domain.LegionTopicAll, payload)
}

func (e *ChatEvent) OnMessage(client socket.IClient, message []byte) {
	var updateReq accountpb.UpdateRequest
	if err := proto.Unmarshal(message, &updateReq); err != nil {
		log.Printf("Ошибка разбора запроса обновления: %v", err)
		return
	}

	if updateReq.State != nil {
		log.Printf("Состояние обновления - pts %d - date %d", updateReq.State.Pts, updateReq.State.Date)
	}

	switch req := updateReq.Update.(type) {
	case nil:
		if updateReq.State != nil {
			_ = client.Write(&accountpb.UpdateResponse{
				State: updateReq.State,
			})
		}

	case *accountpb.UpdateRequest_SystemPingEvent:
		if err := client.Write(&accountpb.UpdateResponse{
			UpdateSystem: &accountpb.UpdateSystem{
				UpdateSystemType: &accountpb.UpdateSystem_SystemPongEvent{
					SystemPongEvent: &accountpb.UpdateSystemPongEvent{},
				},
			},
		}); err != nil {
			log.Printf("Ошибка отправки pong: %v", err)
		}

	case *accountpb.UpdateRequest_SystemPongEvent:
		log.Println("Получен pong от grpc")

	default:
		log.Printf("Неподдерживаемый тип обновления: %T", req)
	}
}

func (e *ChatEvent) OnClose(client socket.IClient, code int, text string) {
	fmt.Printf("OnClose: uid=%v cid=%v канал=%s код=%v текст=%s\n", client.Uid(), client.Cid(), client.Channel().Name(), code, text)
	e.publishUserStatus(context.Background(), client.Uid(), false)
}
