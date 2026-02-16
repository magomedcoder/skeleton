package socket

import (
	"context"
	"time"

	"github.com/magomedcoder/legion/api/pb/accountpb"
	"google.golang.org/protobuf/proto"
)

type GRPCStreamAdapter struct {
	ctx    context.Context
	stream accountpb.AccountService_GetUpdatesServer
}

func NewGRPCStreamAdapter(stream accountpb.AccountService_GetUpdatesServer) (*GRPCStreamAdapter, error) {
	return &GRPCStreamAdapter{
		ctx:    stream.Context(),
		stream: stream,
	}, nil
}

func (g *GRPCStreamAdapter) Read() ([]byte, error) {
	req, err := g.stream.Recv()
	if err != nil {
		return nil, err
	}

	return proto.Marshal(req)
}

func (g *GRPCStreamAdapter) Write(data []byte) error {
	var msg accountpb.UpdateResponse
	if err := proto.Unmarshal(data, &msg); err != nil {
		return err
	}

	return g.stream.Send(&msg)
}

func (g *GRPCStreamAdapter) Close() error {
	select {
	case <-g.ctx.Done():
		return g.ctx.Err()
	case <-time.After(5 * time.Second):
		return context.DeadlineExceeded
	}
}

func (g *GRPCStreamAdapter) SetCloseHandler(fn func(code int, text string) error) {
	go func() {
		<-g.ctx.Done()
		_ = fn(1000, "grpc-поток закрыт")
	}()
}
