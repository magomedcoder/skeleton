package socket

import (
	"context"
	"fmt"
	cmap "github.com/orcaman/concurrent-map/v2"
	"github.com/sourcegraph/conc/pool"
	"log"
	"strconv"
	"sync/atomic"
	"time"
)

type IChannel interface {
	Name() string

	Count() int64

	Client(cid int64) (*Client, bool)

	Write(data *SenderContent)

	addClient(client *Client)

	delClient(client *Client)
}

type Channel struct {
	name    string
	count   int64
	clients cmap.ConcurrentMap[string, *Client]
	outChan chan *SenderContent
}

func NewChannel(name string, outChan chan *SenderContent) *Channel {
	return &Channel{
		name:    name,
		clients: cmap.New[*Client](),
		outChan: outChan,
	}
}

func (c *Channel) Name() string {
	return c.name
}

func (c *Channel) Count() int64 {
	return c.count
}

func (c *Channel) Client(cid int64) (*Client, bool) {
	return c.clients.Get(strconv.FormatInt(cid, 10))
}

func (c *Channel) Write(data *SenderContent) {
	timer := time.NewTimer(3 * time.Second)
	defer timer.Stop()
	select {
	case c.outChan <- data:
	case <-timer.C:
		//log.Printf("Channel timeout %s, channel length: %d \n", c.name, len(c.outChan))
	}
}

func (c *Channel) Start(ctx context.Context) error {
	var (
		worker = pool.New().WithMaxGoroutines(10)
		timer  = time.NewTicker(15 * time.Second)
	)

	defer log.Println(fmt.Errorf("выход из канала: %s", c.Name()))

	defer timer.Stop()

	for {
		select {
		case <-ctx.Done():
			return fmt.Errorf("выход из канала: %s", c.Name())
		case <-timer.C:
			//fmt.Printf("Channel name:%s unix:%d len:%d \n", c.name, time.Now().Unix(), len(c.outChan))
		case payload, ok := <-c.outChan:
			if !ok {
				return fmt.Errorf("закрытие исходящего канала: %s", c.Name())
			}
			c.dispatch(worker, payload)
		}
	}
}

func (c *Channel) dispatch(worker *pool.Pool, data *SenderContent) {
	worker.Go(func() {
		if data.IsBroadcast() {
			c.clients.IterCb(func(_ string, client *Client) {
				_ = client.Write(data.Build())
			})
			return
		}
		for _, cid := range data.recipientIDs {
			if client, ok := c.Client(cid); ok {
				_ = client.Write(data.Build())
			}
		}
	})
}

func (c *Channel) addClient(client *Client) {
	c.clients.Set(strconv.FormatInt(client.cid, 10), client)
	atomic.AddInt64(&c.count, 1)
}

func (c *Channel) delClient(client *Client) {
	cidKey := strconv.FormatInt(client.cid, 10)
	if !c.clients.Has(cidKey) {
		return
	}
	c.clients.Remove(cidKey)
	atomic.AddInt64(&c.count, -1)
}
