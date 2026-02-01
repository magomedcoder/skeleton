OLLAMA_TAG  ?= v0.15.2

.PHONY: deps deps-ollama
deps: deps-ollama

deps-ollama:
	@if [ ! -d "ollama/.git" ]; then \
		echo "Клонируем ollama $(OLLAMA_TAG) в ollama..."; \
		git clone --depth 1 --branch $(OLLAMA_TAG) https://github.com/ollama/ollama.git ollama; \
	else \
		echo "ollama уже существует"; \
	fi

.PHONY: ollama-update
ollama-update:
	@if [ ! -d "ollama/.git" ]; then $(MAKE) deps-ollama; exit 0; fi
	cd ollama \
		&& git fetch --depth 1 origin tag $(OLLAMA_TAG) \
		&& git checkout $(OLLAMA_TAG)

.PHONY: run-ollama
run-ollama: deps-ollama
	#go generate ./...
	#go build -tags cuda .
	# OLLAMA_GPU=1
	# CUDA_VISIBLE_DEVICES=0
	OLLAMA_HOST=0.0.0.0:11434 go run ./ollama/main.go
