package consume

import (
	"context"
	"encoding/json"
	"github.com/magomedcoder/legion/api/pb/accountpb"
	"github.com/magomedcoder/legion/internal/domain/event"
	"github.com/magomedcoder/legion/internal/pkg/socket"
	"github.com/magomedcoder/legion/pkg/sliceutil"
	"log"
	"strconv"
)

func (h *Handler) handleUserStatus(ctx context.Context, payload []byte) {
	var in event.ConsumeUserStatus
	if err := json.Unmarshal(payload, &in); err != nil {
		log.Printf("handleUserStatus: ошибка декодирования json: %s", err)
		return
	}

	chatUserIds := h.ChatUseCase.GetAllUserIds(ctx, in.UserId)
	uniqueIDs := sliceutil.Unique(chatUserIds)

	var clientIDs []int64
	for _, uid := range uniqueIDs {
		ids := h.ClientCache.GetUidFromClientIds(
			ctx,
			h.Conf.ServerId(),
			socket.Session.Chat.Name(),
			strconv.FormatInt(uid, 10),
		)
		if len(ids) > 0 {
			clientIDs = append(clientIDs, ids...)
		}
	}

	if len(clientIDs) == 0 {
		return
	}

	content := socket.NewSenderContent()
	content.SetReceive(clientIDs...)
	content.SetUpdateUserStatus(&accountpb.Update_UserStatus{
		UserStatus: &accountpb.UpdateUserStatus{
			UserId: int64(in.UserId),
			Status: in.Status,
		},
	})
	socket.Session.Chat.Write(content)
}
