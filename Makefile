.PHONY: install
install:
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest \
	&& go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

	git clone https://github.com/googleapis/googleapis.git third_party/proto/googleapis

.PHONY: run
run:
	go run ./cmd/legion

.PHONY: run-runner
run-runner:
	go run -tags nvidia ./cmd/runner

.PHONY: run-runner-llama
run-runner-llama:
	go run -tags llama ./cmd/runner

.PHONY: build
build:
	@mkdir -p build
	go build -o build/legion ./cmd/legion

.PHONY: build-runner
build-runner:
	@mkdir -p build
	go build -o build/legion-runner ./cmd/runner

.PHONY: build-runner-nvidia
build-runner-nvidia:
	@mkdir -p build
	go build -tags nvidia -o build/legion-runner ./cmd/runner

.PHONY: test
test:
	go test ./...

.PHONY: test-load
test-load:
	go test ./tests/load -v -run TestLoad

.PHONY: client-test
client-test:
	cd client-side && flutter test

.PHONY: gen
gen: gen-go-proto gen-dart-proto

.PHONY: gen-go-proto
gen-go-proto:
	@for proto in ./api/proto/*.proto; do \
		name=$$(basename $$proto .proto); \
		mkdir -p ./api/pb/$${name}pb; \
		protoc --proto_path=./api/proto \
			--go_out=paths=source_relative:./api/pb/$${name}pb \
			--go-grpc_out=paths=source_relative:./api/pb/$${name}pb \
			$$proto; \
	done

.PHONY: gen-dart-proto
gen-dart-proto:
	mkdir -p ./client-side/lib/generated/grpc_pb
	protoc --proto_path=./api/proto \
		--dart_out=grpc:./client-side/lib/generated/grpc_pb \
		./api/proto/*.proto

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
