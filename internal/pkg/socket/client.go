package socket

import (
	"context"
	"fmt"
	"log"
	"sync/atomic"
	"time"

	"github.com/magomedcoder/legion/api/pb/accountpb"
	"github.com/magomedcoder/legion/pkg/strutil"
	"google.golang.org/protobuf/proto"
)

const (
	_MsgEventPing = "ping"
	_MsgEventPong = "pong"
	_MsgEventAck  = "ack"
)

type IClient interface {
	Cid() int64

	Uid() int

	Close(code int, text string)

	Write(data *accountpb.UpdateResponse) error

	Channel() IChannel
}

type IStorage interface {
	Bind(ctx context.Context, channel string, cid int64, uid int) error

	UnBind(ctx context.Context, channel string, cid int64) error
}

type Client struct {
	conn     IConn
	cid      int64
	uid      int
	lastTime int64
	closed   int32
	channel  IChannel
	storage  IStorage
	event    IEvent
	outChan  chan *accountpb.UpdateResponse
}

const DefaultWriteBufferSize = 10

type ClientOption struct {
	Uid         int
	Channel     IChannel
	Storage     IStorage
	IDGenerator IDGenerator
	Buffer      int
}

func NewClient(conn IConn, option *ClientOption, event IEvent) error {
	if option.Buffer <= 0 {
		option.Buffer = DefaultWriteBufferSize
	}
	if event == nil {
		panic("socket: event handler is required")
	}

	client := &Client{
		conn:     conn,
		uid:      option.Uid,
		lastTime: time.Now().Unix(),
		channel:  option.Channel,
		storage:  option.Storage,
		outChan:  make(chan *accountpb.UpdateResponse, option.Buffer),
		event:    event,
	}
	if option.IDGenerator != nil {
		client.cid = option.IDGenerator.ID()
	} else {
		client.cid = defaultIDGenerator.ID()
	}

	conn.SetCloseHandler(client.hookClose)
	if client.storage != nil {
		if err := client.storage.Bind(context.TODO(), client.channel.Name(), client.cid, client.uid); err != nil {
			log.Printf("Ошибка привязки клиента: %s", err)
			return err
		}
	}

	client.channel.addClient(client)
	client.event.Open(client)
	health.insert(client)

	return client.init()
}

func (c *Client) Channel() IChannel {
	return c.channel
}

func (c *Client) Cid() int64 {
	return c.cid
}

func (c *Client) Uid() int {
	return c.uid
}

func (c *Client) Close(code int, message string) {
	defer func() {
		if err := c.conn.Close(); err != nil {
			log.Printf("Ошибка закрытия соединения: %s", err.Error())
		}
	}()

	if err := c.hookClose(code, message); err != nil {
		log.Printf("%s-%d-%d ошибка закрытия grpc: %s", c.channel.Name(), c.cid, c.uid, err)
	}
}

func (c *Client) Closed() bool {
	return atomic.LoadInt32(&c.closed) == 1
}

func (c *Client) Write(data *accountpb.UpdateResponse) error {
	defer func() {
		if err := recover(); err != nil {
			log.Printf("%s-%d-%d ошибка записи в канал: %v", c.channel.Name(), c.cid, c.uid, err)
		}
	}()
	if c.Closed() {
		return fmt.Errorf("соединение закрыто")
	}

	getSystemEvent := data.UpdateSystem.GetSystemEvent()
	if getSystemEvent.GetIsAck() {
		getSystemEvent.Sid = strutil.NewMsgId()
	}

	c.outChan <- data

	return nil
}

func (c *Client) loopAccept() {
	defer c.Close(1000, "цикл приёма закрыт")
	for {
		data, err := c.conn.Read()
		if err != nil {
			break
		}
		c.lastTime = time.Now().Unix()
		c.handleMessage(data)
	}
}

func (c *Client) loopWrite() {
	timer := time.NewTimer(15 * time.Second)
	defer timer.Stop()
	for {
		timer.Reset(15 * time.Second)
		select {
		case <-timer.C:
		//	log.Printf("Client cid:%d uid:%d time:%d", c.cid, c.uid, time.Now().Unix())
		case data, ok := <-c.outChan:
			if !ok || c.Closed() {
				return
			}

			bt, err := proto.Marshal(data)
			if err != nil {
				log.Printf("loopWrite: ошибка маршалинга proto: %v", err)
				continue
			}

			if err := c.conn.Write(bt); err != nil {
				log.Printf("%s-%d-%d ошибка записи grpc: %v", c.channel.Name(), c.cid, c.uid, err)
				return
			}

			getSystemEvent := data.UpdateSystem.GetSystemEvent()
			if getSystemEvent.GetIsAck() && getSystemEvent.GetRetry() > 0 {
				getSystemEvent.Retry--
				ack.insert(getSystemEvent.Sid, &AckBufferContent{
					Cid:      c.cid,
					Uid:      int64(c.uid),
					Channel:  c.channel.Name(),
					Response: data,
				})
			}
		}
	}
}

func (c *Client) init() error {
	_ = c.Write(&accountpb.UpdateResponse{
		UpdateSystem: &accountpb.UpdateSystem{
			UpdateSystemType: &accountpb.UpdateSystem_SystemPingIntervalEvent{
				SystemPingIntervalEvent: &accountpb.UpdateSystemPingIntervalEvent{
					PingInterval: fmt.Sprintf("%d", heartbeatIntervalSec),
					PingTimeout:  fmt.Sprintf("%d", heartbeatTimeoutSec),
				},
			},
		},
	})

	go c.loopWrite()
	go c.loopAccept()

	return nil
}

func (c *Client) hookClose(code int, text string) error {
	if !atomic.CompareAndSwapInt32(&c.closed, 0, 1) {
		return nil
	}

	close(c.outChan)
	c.event.Close(c, code, text)
	if c.storage != nil {
		if err := c.storage.UnBind(context.TODO(), c.channel.Name(), c.cid); err != nil {
			log.Printf("Ошибка отвязки grpc: %s", err)
			return err
		}
	}

	health.delete(c)
	c.channel.delClient(c)

	return nil
}

func (c *Client) handleMessage(data []byte) {
	var msg accountpb.UpdateSystem
	if err := proto.Unmarshal(data, &msg); err != nil {
		log.Printf("Ошибка проверки: ошибка декодирования proto: %v", err)
		return
	}

	switch update := msg.GetUpdateSystemType().(type) {
	case *accountpb.UpdateSystem_SystemEvent:
		systemEvent := update.SystemEvent
		switch systemEvent.GetEvent() {
		case _MsgEventPing:
			_ = c.Write(&accountpb.UpdateResponse{
				UpdateSystem: &accountpb.UpdateSystem{
					UpdateSystemType: &accountpb.UpdateSystem_SystemPongEvent{
						SystemPongEvent: &accountpb.UpdateSystemPongEvent{},
					},
				},
			})
		case _MsgEventPong:
			//
		case _MsgEventAck:
			if ackId := systemEvent.GetSid(); ackId != "" {
				ack.delete(ackId)
			}
		default:
			c.event.Message(c, data)
		}
	default:
		c.event.Message(c, data)
	}
}
