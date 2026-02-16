package grpc

import (
	"context"
	"github.com/magomedcoder/legion/api/pb/accountpb"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"log"
	"sync"
	"testing"
	"time"
)

func TestUpdatesService(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*30)
	defer cancel()

	conn, err := grpc.NewClient("127.0.0.1:50051",
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithUnaryInterceptor(unaryInterceptor),
		grpc.WithStreamInterceptor(streamInterceptor),
	)
	if err != nil {
		log.Println("Не удалось подключиться к gRPC серверу")
	}
	defer conn.Close()

	client := accountpb.NewAccountServiceClient(conn)

	t.Run("TestGetUpdatesStream", func(t *testing.T) {
		testGetUpdatesStream(t, ctx, client)
	})

	t.Run("TestGetUpdatesWithPingPong", func(t *testing.T) {
		testGetUpdatesWithPingPong(t, ctx, client)
	})

	t.Run("TestGetUpdatesWithDifferentEvents", func(t *testing.T) {
		testGetUpdatesWithDifferentEvents(t, ctx, client)
	})
}

func testGetUpdatesStream(t *testing.T, ctx context.Context, client accountpb.AccountServiceClient) {
	streamCtx, streamCancel := context.WithTimeout(ctx, time.Second*15)
	defer streamCancel()

	stream, err := client.GetUpdates(streamCtx)
	if err != nil {
		t.Fatalf("Ошибка при создании потока GetUpdates: %v", err)
	}

	var wg sync.WaitGroup
	wg.Add(2)

	go func() {
		defer wg.Done()

		initialReq := &accountpb.UpdateRequest{
			State: &accountpb.UpdateState{
				Pts:  0,
				Date: time.Now().Unix(),
			},
		}

		if err := stream.Send(initialReq); err != nil {
			t.Errorf("Ошибка при отправке начального запроса: %v", err)
			return
		}
		log.Println("Отправлен начальный запрос")

		ticker := time.NewTicker(5 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				pingReq := &accountpb.UpdateRequest{
					Update: &accountpb.UpdateRequest_SystemPingEvent{
						SystemPingEvent: &accountpb.UpdateSystemPingEvent{},
					},
				}
				if err := stream.Send(pingReq); err != nil {
					t.Errorf("Ошибка при отправке пинга: %v", err)
					return
				}
				log.Println("Отправлен пинг")

			case <-streamCtx.Done():
				return
			}
		}
	}()

	go func() {
		defer wg.Done()
		updateCount := 0

		for {
			select {
			case <-streamCtx.Done():
				return
			default:
				resp, err := stream.Recv()
				if err != nil {
					t.Errorf("Ошибка при получении обновления: %v", err)
					return
				}

				log.Printf("Получено обновление: PTS=%d, Date=%d", resp.GetState().GetPts(), resp.GetState().GetDate())

				if sysUpdate := resp.GetUpdateSystem(); sysUpdate != nil {
					handleSystemUpdate(t, sysUpdate)
				}

				if len(resp.GetUpdates()) > 0 {
					for _, update := range resp.GetUpdates() {
						handleApplicationUpdate(t, update)
						updateCount++
					}
				}

				if updateCount >= 5 {
					log.Printf("Получено %d обновлений, завершаем тест", updateCount)
					streamCancel()
					return
				}
			}
		}
	}()

	wg.Wait()
}

func testGetUpdatesWithPingPong(t *testing.T, ctx context.Context, client accountpb.AccountServiceClient) {
	streamCtx, streamCancel := context.WithTimeout(ctx, time.Second*10)
	defer streamCancel()

	stream, err := client.GetUpdates(streamCtx)
	if err != nil {
		t.Fatalf("Ошибка при создании потока: %v", err)
	}

	pingReq := &accountpb.UpdateRequest{
		Update: &accountpb.UpdateRequest_SystemPingEvent{
			SystemPingEvent: &accountpb.UpdateSystemPingEvent{},
		},
	}

	if err := stream.Send(pingReq); err != nil {
		t.Fatalf("Ошибка при отправке ping: %v", err)
	}

	resp, err := stream.Recv()
	if err != nil {
		t.Fatalf("Ошибка при получении ответа: %v", err)
	}

	if sysUpdate := resp.GetUpdateSystem(); sysUpdate != nil {
		if pingInterval := sysUpdate.GetSystemPingIntervalEvent(); pingInterval != nil {
			log.Printf("Получены настройки ping: interval=%s, timeout=%s", pingInterval.GetPingInterval(), pingInterval.GetPingTimeout())
			t.Log("Ping-pong механизм работает корректно")
		}
	}

	pongReq := &accountpb.UpdateRequest{
		Update: &accountpb.UpdateRequest_SystemPongEvent{
			SystemPongEvent: &accountpb.UpdateSystemPongEvent{},
		},
	}

	if err := stream.Send(pongReq); err != nil {
		t.Fatalf("Ошибка при отправке pong: %v", err)
	}

	t.Log("Ping-pong тест пройден успешно")
}

func testGetUpdatesWithDifferentEvents(t *testing.T, ctx context.Context, client accountpb.AccountServiceClient) {
	streamCtx, streamCancel := context.WithTimeout(ctx, time.Second*10)
	defer streamCancel()

	stream, err := client.GetUpdates(streamCtx)
	if err != nil {
		t.Fatalf("Ошибка при создании потока: %v", err)
	}

	testCases := []struct {
		name string
		req  *accountpb.UpdateRequest
	}{
		{
			name: "Initial state",
			req: &accountpb.UpdateRequest{
				State: &accountpb.UpdateState{
					Pts:  100,
					Date: time.Now().Unix(),
				},
			},
		},
		{
			name: "System ping",
			req: &accountpb.UpdateRequest{
				Update: &accountpb.UpdateRequest_SystemPingEvent{
					SystemPingEvent: &accountpb.UpdateSystemPingEvent{},
				},
			},
		},
		{
			name: "System pong",
			req: &accountpb.UpdateRequest{
				Update: &accountpb.UpdateRequest_SystemPongEvent{
					SystemPongEvent: &accountpb.UpdateSystemPongEvent{},
				},
			},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			if err := stream.Send(tc.req); err != nil {
				t.Errorf("Ошибка при отправке %s: %v", tc.name, err)
				return
			}

			resp, err := stream.Recv()
			if err != nil {
				t.Errorf("Ошибка при получении ответа на %s: %v", tc.name, err)
				return
			}

			t.Logf("Получен ответ на %s: PTS=%d", tc.name, resp.GetState().GetPts())
		})
	}
}

func handleSystemUpdate(t *testing.T, sysUpdate *accountpb.UpdateSystem) {
	switch update := sysUpdate.GetUpdateSystemType().(type) {
	case *accountpb.UpdateSystem_SystemPingIntervalEvent:
		pingInterval := update.SystemPingIntervalEvent
		t.Logf("Системное обновление: PingIntervalEvent - interval=%s, timeout=%s", pingInterval.GetPingInterval(), pingInterval.GetPingTimeout())

	case *accountpb.UpdateSystem_SystemPingEvent:
		t.Log("Системное обновление: PingEvent")

	case *accountpb.UpdateSystem_SystemPongEvent:
		t.Log("Системное обновление: PongEvent")

	case *accountpb.UpdateSystem_SystemAckEvent:
		t.Logf("Системное обновление: AckEvent - sid=%s", update.SystemAckEvent.GetSid())

	case *accountpb.UpdateSystem_SystemEvent:
		sysEvent := update.SystemEvent
		t.Logf("Системное обновление: SystemEvent - event=%s, sid=%s, is_ack=%v, retry=%d", sysEvent.GetEvent(), sysEvent.GetSid(), sysEvent.GetIsAck(), sysEvent.GetRetry())
	}
}

func handleApplicationUpdate(t *testing.T, update *accountpb.Update) {
	switch upd := update.GetUpdateType().(type) {

	case *accountpb.Update_UserStatus:
		statusUpdate := upd.UserStatus
		t.Logf("Изменение статуса: user_id=%d, status=%v", statusUpdate.GetUserId(), statusUpdate.GetStatus())

	}
}

func TestGetUpdatesReconnect(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*20)
	defer cancel()

	conn, err := grpc.NewClient("127.0.0.1:50051",
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithUnaryInterceptor(unaryInterceptor),
		grpc.WithStreamInterceptor(streamInterceptor),
	)
	if err != nil {
		log.Println("Не удалось подключиться к gRPC серверу")
	}
	defer conn.Close()

	client := accountpb.NewAccountServiceClient(conn)

	stream1, err := client.GetUpdates(ctx)
	if err != nil {
		t.Fatalf("Ошибка при первом подключении: %v", err)
	}

	initialReq := &accountpb.UpdateRequest{
		State: &accountpb.UpdateState{
			Pts:  0,
			Date: time.Now().Unix(),
		},
	}
	if err := stream1.Send(initialReq); err != nil {
		t.Fatalf("Ошибка при отправке начального запроса: %v", err)
	}

	resp1, err := stream1.Recv()
	if err != nil {
		t.Fatalf("Ошибка при получении первого ответа: %v", err)
	}
	t.Logf("Первое подключение: PTS=%d", resp1.GetState().GetPts())

	stream1.CloseSend()

	time.Sleep(2 * time.Second)

	stream2, err := client.GetUpdates(ctx)
	if err != nil {
		t.Fatalf("Ошибка при втором подключении: %v", err)
	}

	reconnectReq := &accountpb.UpdateRequest{
		State: resp1.GetState(),
	}
	if err := stream2.Send(reconnectReq); err != nil {
		t.Fatalf("Ошибка при отправке запроса повторного подключения: %v", err)
	}

	resp2, err := stream2.Recv()
	if err != nil {
		t.Fatalf("Ошибка при получении ответа повторного подключения: %v", err)
	}

	t.Logf("Второе подключение: PTS=%d", resp2.GetState().GetPts())
}
