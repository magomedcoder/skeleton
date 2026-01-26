.PHONY: install
install:
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest \
	&& go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

.PHONY: gen
gen:
	@for proto in ./api/proto/*.proto; do \
		name=$$(basename $$proto .proto); \
		mkdir -p ./api/pb/$${name}pb; \
		protoc --proto_path=./api/proto \
			--go_out=paths=source_relative:./api/pb/$${name}pb \
			--go-grpc_out=paths=source_relative:./api/pb/$${name}pb \
			$$proto; \
	done

	mkdir -p ./client-side/lib/generated/grpc_pb
	protoc --proto_path=./api/proto \
		--dart_out=grpc:./client-side/lib/generated/grpc_pb \
		./api/proto/*.proto

.PHONY: run
run:
	go run ./cmd/legion

.PHONY: run-ollama
run-ollama:
	#go generate ./...
	#go build -tags cuda .
	# OLLAMA_GPU=1
	# CUDA_VISIBLE_DEVICES=0
	OLLAMA_HOST=0.0.0.0:11434 go run ./third_party/ollama/main.go
