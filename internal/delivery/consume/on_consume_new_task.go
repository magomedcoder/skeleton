package consume

import (
	"context"
	"encoding/json"
	"log"
	"strconv"

	"github.com/magomedcoder/legion/api/pb/accountpb"
	"github.com/magomedcoder/legion/api/pb/projectpb"
	"github.com/magomedcoder/legion/internal/domain/event"
	"github.com/magomedcoder/legion/internal/pkg/socket"
)

func (h *Handler) onConsumeNewTask(ctx context.Context, body []byte) {
	var in event.ConsumeTask
	if err := json.Unmarshal(body, &in); err != nil {
		log.Printf("onConsumeNewTask: ошибка декодирования json: %s", err)
		return
	}
	if in.ProjectId == "" || in.TaskId == "" {
		return
	}

	memberIds, err := h.ProjectUseCase.GetProjectMemberIds(ctx, in.ProjectId)
	if err != nil {
		log.Printf("onConsumeNewTask: не удалось получить участников проекта %s: %v", in.ProjectId, err)
		return
	}

	var clientIds []int64
	for _, uid := range memberIds {
		ids := h.ClientCache.GetUidFromClientIds(ctx,
			h.Conf.ServerId(),
			socket.Session.Chat.Name(),
			strconv.Itoa(uid),
		)
		clientIds = append(clientIds, ids...)
	}
	if len(clientIds) == 0 {
		return
	}

	task, err := h.ProjectUseCase.GetTaskById(ctx, in.TaskId)
	if err != nil {
		log.Printf("onConsumeNewTask: не удалось получить задачу %s: %v", in.TaskId, err)
		return
	}

	protoTask := &projectpb.Task{
		Id:          task.Id,
		Name:        task.Name,
		Description: task.Description,
		CreatedAt:   task.CreatedAt,
		Assigner:    int64(task.Assigner),
		Executor:    int64(task.Executor),
		ColumnId:    task.ColumnId,
	}

	c := socket.NewSenderContent()
	c.SetReceive(clientIds...)
	c.SetAck(true)
	c.SetUpdateNewTask(&accountpb.Update_NewTask{
		NewTask: &accountpb.UpdateNewTask{
			ProjectId: in.ProjectId,
			Task:      protoTask,
		},
	})

	socket.Session.Chat.Write(c)
}
