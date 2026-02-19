package consume

import (
	"context"
	"encoding/json"
	"log"
	"strconv"

	"github.com/magomedcoder/legion/api/pb/accountpb"
	"github.com/magomedcoder/legion/api/pb/chatpb"
	"github.com/magomedcoder/legion/api/pb/commonpb"
	"github.com/magomedcoder/legion/internal/domain/event"
	"github.com/magomedcoder/legion/internal/pkg/socket"
)

func (h *Handler) onConsumeMessage(ctx context.Context, body []byte) {
	var in event.ConsumeMessage
	if err := json.Unmarshal(body, &in); err != nil {
		log.Printf("onConsumeMessage: ошибка декодирования json: %s", err)
		return
	}

	var clientIds []int64
	for _, val := range [2]int64{in.PeerId, in.FromPeerId} {
		ids := h.ClientCache.GetUidFromClientIds(ctx,
			h.Conf.ServerId(),
			socket.Session.Chat.Name(),
			strconv.FormatInt(val, 10),
		)
		clientIds = append(clientIds, ids...)
	}

	if len(clientIds) == 0 {
		return
	}

	msg, err := h.ChatUseCase.GetMessageById(ctx, in.MessageId)
	if err != nil {
		log.Printf("onConsumeMessage: не удалось получить сообщение %d: %v", in.MessageId, err)
		return
	}

	protoMsg := &chatpb.Message{
		Id:       strconv.FormatInt(msg.Id, 10),
		Peer:     &commonpb.Peer{Peer: &commonpb.Peer_UserId{UserId: int64(msg.PeerId)}},
		FromPeer: &commonpb.Peer{Peer: &commonpb.Peer_UserId{UserId: int64(msg.FromPeerId)}},
		Content:  msg.Content,
		CreatedAt: msg.CreatedAt.Unix(),
	}

	c := socket.NewSenderContent()
	c.SetReceive(clientIds...)
	c.SetAck(true)
	c.SetUpdateNewMessage(&accountpb.Update_NewMessage{
		NewMessage: &accountpb.UpdateNewMessage{
			Message: protoMsg,
		},
	})

	socket.Session.Chat.Write(c)
}
