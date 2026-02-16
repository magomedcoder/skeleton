package grpc

import (
	"context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

const testAuthToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJ1c2VybmFtZSI6ImFkbWluIiwiZXhwIjoxNzcxMjU5OTQxLCJuYmYiOjE3NzEyNTkwNDEsImlhdCI6MTc3MTI1OTA0MSwianRpIjoiMzQ0NmY5NWUtMTk2MC00MGE2LTg5NGEtMTU3NTI0NTlmMWJhIn0.GzN9L0g5JFOJRiCVBVrl3LrZQS4h5WqvCN1LEYq6-mQ"

func authMetadata(ctx context.Context) context.Context {
	md := metadata.Pairs("Authorization", "Bearer "+testAuthToken)
	return metadata.NewOutgoingContext(ctx, md)
}

func unaryInterceptor(ctx context.Context, method string, req, reply any, cc *grpc.ClientConn, invoker grpc.UnaryInvoker, opts ...grpc.CallOption) error {
	return invoker(authMetadata(ctx), method, req, reply, cc, opts...)
}

func streamInterceptor(ctx context.Context, desc *grpc.StreamDesc, cc *grpc.ClientConn, method string, streamer grpc.Streamer, opts ...grpc.CallOption) (grpc.ClientStream, error) {
	return streamer(authMetadata(ctx), desc, cc, method, opts...)
}
