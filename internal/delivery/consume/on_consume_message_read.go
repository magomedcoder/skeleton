package consume

import (
	"context"
	"encoding/json"
	"github.com/magomedcoder/legion/api/pb/accountpb"
	"github.com/magomedcoder/legion/internal/domain/event"
	"github.com/magomedcoder/legion/internal/pkg/socket"
	"log"
	"strconv"
)

func (h *Handler) onConsumeMessageRead(ctx context.Context, body []byte) {
	var in event.ConsumeMessageRead
	if err := json.Unmarshal(body, &in); err != nil {
		log.Printf("onConsumeMessageRead: ошибка декодирования json: %s", err)
		return
	}

	clientIds := h.ClientCache.GetUidFromClientIds(ctx,
		h.Conf.ServerId(),
		socket.Session.Chat.Name(),
		strconv.FormatInt(in.PeerId, 10),
	)
	if len(clientIds) == 0 {
		return
	}

	c := socket.NewSenderContent()
	c.SetReceive(clientIds...)
	c.SetAck(true)
	c.SetUpdateMessageRead(&accountpb.Update_MessageRead{
		MessageRead: &accountpb.UpdateMessageRead{
			ReaderUserId:      in.ReaderId,
			PeerUserId:        in.PeerId,
			LastReadMessageId: in.LastReadMessageId,
		},
	})

	socket.Session.Chat.Write(c)
}
