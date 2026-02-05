package runner

import (
	"context"
	"fmt"
	"github.com/magomedcoder/skeleton/api/pb/chatpb"
	"github.com/magomedcoder/skeleton/api/pb/runnerpb"
	"github.com/magomedcoder/skeleton/internal/domain"
	"github.com/magomedcoder/skeleton/internal/mappers"
	"github.com/magomedcoder/skeleton/pkg/logger"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"sync"
	"sync/atomic"
)

type Pool struct {
	addresses []string
	disabled  map[string]bool
	mu        sync.RWMutex
	index     atomic.Uint32
	conns     map[string]*grpc.ClientConn
	connMu    sync.Mutex
}

func NewPool(addresses []string) *Pool {
	p := &Pool{
		addresses: make([]string, 0, len(addresses)),
		disabled:  make(map[string]bool),
		conns:     make(map[string]*grpc.ClientConn),
	}

	for _, a := range addresses {
		if a != "" {
			p.addresses = append(p.addresses, a)
		}
	}

	return p
}

func (p *Pool) Add(address string) {
	if address == "" {
		return
	}

	p.mu.Lock()
	defer p.mu.Unlock()

	for _, a := range p.addresses {
		if a == address {
			return
		}
	}

	p.addresses = append(p.addresses, address)
}

func (p *Pool) Remove(address string) {
	p.mu.Lock()
	defer p.mu.Unlock()

	for i, a := range p.addresses {
		if a == address {
			p.addresses = append(p.addresses[:i], p.addresses[i+1:]...)
			break
		}
	}

	p.closeConn(address)
}

func (p *Pool) closeConn(address string) {
	p.connMu.Lock()
	defer p.connMu.Unlock()

	if conn, ok := p.conns[address]; ok {
		_ = conn.Close()
		delete(p.conns, address)
	}
}

func (p *Pool) getConn(ctx context.Context, address string) (runnerpb.RunnerServiceClient, error) {
	p.connMu.Lock()
	defer p.connMu.Unlock()

	if conn, ok := p.conns[address]; ok {
		return runnerpb.NewRunnerServiceClient(conn), nil
	}

	conn, err := grpc.NewClient(address, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		logger.W("Pool: ошибка подключения к раннеру %s: %v", address, err)
		return nil, fmt.Errorf("подключение к раннеру %s: %w", address, err)
	}

	logger.D("Pool: подключение к раннеру %s установлено", address)
	p.conns[address] = conn

	return runnerpb.NewRunnerServiceClient(conn), nil
}

func (p *Pool) enabledAddresses() []string {
	p.mu.RLock()
	defer p.mu.RUnlock()

	out := make([]string, 0, len(p.addresses))
	for _, a := range p.addresses {
		if !p.disabled[a] {
			out = append(out, a)
		}
	}

	return out
}

func (p *Pool) pickRunner() (string, bool) {
	addrs := p.enabledAddresses()
	if len(addrs) == 0 {
		return "", false
	}

	i := p.index.Add(1) % uint32(len(addrs))
	return addrs[i], true
}

func (p *Pool) GetRunners() []RunnerInfo {
	p.mu.RLock()
	addrs := make([]string, len(p.addresses))
	copy(addrs, p.addresses)
	disabledCopy := make(map[string]bool)
	for k, v := range p.disabled {
		disabledCopy[k] = v
	}
	p.mu.RUnlock()

	p.connMu.Lock()
	connStatus := make(map[string]bool)
	for a := range p.conns {
		connStatus[a] = true
	}
	p.connMu.Unlock()

	out := make([]RunnerInfo, len(addrs))
	for i, a := range addrs {
		enabled := !disabledCopy[a]
		out[i] = RunnerInfo{
			Address:   a,
			Enabled:   enabled,
			Connected: connStatus[a] && enabled,
		}
	}
	return out
}

func (p *Pool) SetRunnerEnabled(address string, enabled bool) {
	p.mu.Lock()
	defer p.mu.Unlock()

	for _, a := range p.addresses {
		if a == address {
			if enabled {
				delete(p.disabled, address)
			} else {
				p.disabled[address] = true
				p.closeConn(address)
			}
			return
		}
	}
}

func (p *Pool) HasActiveRunners() bool {
	return len(p.enabledAddresses()) > 0
}

type RunnerInfo struct {
	Address   string
	Enabled   bool
	Connected bool
}

func (p *Pool) CheckConnection(ctx context.Context) (bool, error) {
	addrs := p.enabledAddresses()
	if len(addrs) == 0 {
		return false, fmt.Errorf("нет активных раннеров")
	}

	for _, addr := range addrs {
		client, err := p.getConn(ctx, addr)
		if err != nil {
			continue
		}

		resp, err := client.Ping(ctx, &runnerpb.Empty{})
		if err == nil && resp != nil && resp.Ok {
			return true, nil
		}
	}

	return false, fmt.Errorf("ни один раннер не отвечает")
}

func (p *Pool) GetModels(ctx context.Context) ([]string, error) {
	addrs := p.enabledAddresses()
	if len(addrs) == 0 {
		return nil, fmt.Errorf("нет активных раннеров")
	}

	for _, addr := range addrs {
		client, err := p.getConn(ctx, addr)
		if err != nil {
			continue
		}

		resp, err := client.GetModels(ctx, &runnerpb.Empty{})
		if err == nil && resp != nil {
			return resp.Models, nil
		}
	}

	return nil, fmt.Errorf("ни один раннер не вернул список моделей")
}

func (p *Pool) GetGpuInfo(ctx context.Context, address string) *runnerpb.GetGpuInfoResponse {
	client, err := p.getConn(ctx, address)
	if err != nil {
		return nil
	}

	resp, err := client.GetGpuInfo(ctx, &runnerpb.Empty{})
	if err != nil || resp == nil {
		return nil
	}

	return resp
}

func (p *Pool) GetServerInfo(ctx context.Context, address string) *runnerpb.ServerInfo {
	client, err := p.getConn(ctx, address)
	if err != nil {
		return nil
	}

	resp, err := client.GetServerInfo(ctx, &runnerpb.Empty{})
	if err != nil || resp == nil {
		return nil
	}

	return resp
}

func (p *Pool) SendMessage(ctx context.Context, sessionID string, model string, messages []*domain.Message) (chan string, error) {
	addr, ok := p.pickRunner()
	if !ok {
		logger.W("Pool: нет доступных раннеров для сессии %s", sessionID)
		return nil, fmt.Errorf("нет доступных раннеров")
	}

	logger.V("Pool: выбран раннер %s для сессии %s", addr, sessionID)
	client, err := p.getConn(ctx, addr)
	if err != nil {
		return nil, err
	}

	protoMessages := make([]*chatpb.ChatMessage, len(messages))
	for i, m := range messages {
		protoMessages[i] = mappers.MessageToProto(m)
	}
	req := &runnerpb.GenerateRequest{
		SessionId: sessionID,
		Messages:  protoMessages,
		Model:     model,
	}

	stream, err := client.Generate(ctx, req)
	if err != nil {
		return nil, fmt.Errorf("runner %s: %w", addr, err)
	}

	out := make(chan string, 100)
	go func() {
		defer close(out)
		for {
			resp, err := stream.Recv()
			if err != nil {
				return
			}

			if resp.Content != "" {
				select {
				case <-ctx.Done():
					return
				case out <- resp.Content:
				}
			}
			if resp.Done {
				return
			}
		}
	}()

	return out, nil
}
