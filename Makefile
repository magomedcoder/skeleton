.PHONY: run
run:
	go run ./cmd/skeleton

.PHONY: run-runner
run-runner:
	go run -tags nvidia ./cmd/runner

.PHONY: build
build:
	@mkdir -p build
	go build -o build/skeleton ./cmd/skeleton

.PHONY: build-runner
build-runner:
	@mkdir -p build
	go build -o build/skeleton-runner ./cmd/runner

.PHONY: build-runner-nvidia
build-runner-nvidia:
	@mkdir -p build
	go build -tags nvidia -o build/skeleton-runner ./cmd/runner

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

.PHONY: install
install:
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest \
	&& go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

.PHONY: deps
deps:
	$(MAKE) -C third_party -f Makefile deps

.PHONY: build-llama build-llama-cublas
build-llama: deps
	@if [ ! -L pkg/llama.cpp/llama_lib ] && [ ! -d pkg/llama.cpp/llama_lib ]; then \
		ln -sf ../../third_party/llama.cpp pkg/llama.cpp/llama_lib; \
		echo "Создан симлинк"; \
	fi

	$(MAKE) -C pkg/llama.cpp libllama.a

build-llama-cublas: deps
	@if [ ! -L pkg/llama.cpp/llama_lib ] && [ ! -d pkg/llama.cpp/llama_lib ]; then \
		ln -sf ../../third_party/llama.cpp pkg/llama.cpp/llama_lib; \
		echo "Создан симлинк"; \
	fi

	$(MAKE) -C pkg/llama.cpp libllama.a BUILD_TYPE=cublas
