package socket

import (
	"context"
	"errors"
	"github.com/magomedcoder/legion/api/pb/accountpb"
	"github.com/magomedcoder/legion/pkg/timeutil"
	"strconv"
	"time"
)

const (
	heartbeatIntervalSec = 30
	heartbeatTimeoutSec  = 75
)

var health *heartbeat

type heartbeat struct {
	TimeWheel *timeutil.SimpleTimeWheel[*Client]
}

func init() {
	health = &heartbeat{}
	health.TimeWheel = timeutil.NewSimpleTimeWheel[*Client](1*time.Second, 100, health.handle)
}

func (h *heartbeat) Start(ctx context.Context) error {
	go h.TimeWheel.Start()
	<-ctx.Done()
	h.TimeWheel.Stop()

	return errors.New("выход из сердцебиения")
}

func (h *heartbeat) insert(c *Client) {
	h.TimeWheel.Add(strconv.FormatInt(c.cid, 10), c, heartbeatIntervalSec*time.Second)
}

func (h *heartbeat) delete(c *Client) {
	h.TimeWheel.Remove(strconv.FormatInt(c.cid, 10))
}

func (h *heartbeat) handle(timeWheel *timeutil.SimpleTimeWheel[*Client], key string, c *Client) {
	if c.Closed() {
		return
	}

	interval := int(time.Now().Unix() - c.lastTime)
	if interval > heartbeatTimeoutSec {
		c.Close(2000, "Превышено время ожидания проверки сердцебиения, соединение автоматически закрыто")
		return
	}

	if interval > heartbeatIntervalSec {
		_ = c.Write(&accountpb.UpdateResponse{
			UpdateSystem: &accountpb.UpdateSystem{
				UpdateSystemType: &accountpb.UpdateSystem_SystemPingEvent{
					SystemPingEvent: &accountpb.UpdateSystemPingEvent{},
				},
			},
		})
	}

	timeWheel.Add(key, c, heartbeatIntervalSec*time.Second)
}
