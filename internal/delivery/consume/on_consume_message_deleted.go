package consume

import (
	"context"
	"encoding/json"
	"github.com/magomedcoder/legion/api/pb/accountpb"
	"github.com/magomedcoder/legion/api/pb/commonpb"
	"github.com/magomedcoder/legion/internal/domain/event"
	"github.com/magomedcoder/legion/internal/pkg/socket"
	"log"
	"strconv"
)

func (h *Handler) onConsumeMessageDeleted(ctx context.Context, body []byte) {
	var in event.ConsumeMessageDeleted
	if err := json.Unmarshal(body, &in); err != nil {
		log.Printf("onConsumeMessageDeleted: ошибка декодирования json: %s", err)
		return
	}

	if len(in.MessageIds) == 0 {
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

	c := socket.NewSenderContent()
	c.SetReceive(clientIds...)
	c.SetAck(true)
	c.SetUpdateMessageDeleted(&accountpb.Update_MessageDeleted{
		MessageDeleted: &accountpb.UpdateMessageDeleted{
			Peer: &commonpb.Peer{
				Peer: &commonpb.Peer_UserId{
					UserId: in.PeerId,
				},
			},
			FromPeer: &commonpb.Peer{
				Peer: &commonpb.Peer_UserId{
					UserId: in.FromPeerId,
				},
			},
			MessageIds: in.MessageIds,
		},
	})

	socket.Session.Chat.Write(c)
}
