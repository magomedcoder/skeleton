.PHONY: gen
gen:
	protoc --proto_path=./api/proto \
	   --go_out=paths=source_relative:./api/pb \
	   --go-grpc_out=paths=source_relative:./api/pb \
	   ./api/proto/*.proto

.PHONY: run
run:
	go run ./cmd/server
