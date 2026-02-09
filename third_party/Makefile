OLLAMA_TAG  ?= v0.15.2
LLAMA_CPP_TAG ?= b7925

.PHONY: deps
deps: deps-ollama deps-llama.cpp

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

deps-llama.cpp:
	@if [ ! -d "llama.cpp/.git" ]; then \
		echo "Клонируем llama.cpp $(LLAMA_CPP_TAG) в llama.cpp..."; \
		git clone --depth 1 --branch $(LLAMA_CPP_TAG) https://github.com/ggml-org/llama.cpp.git llama.cpp; \
	else \
		echo "llama.cpp уже существует"; \
	fi

.PHONY: llama.cpp-update
llama.cpp-update:
	@if [ ! -d "llama.cpp/.git" ]; then $(MAKE) deps-llama.cpp; exit 0; fi
	cd llama.cpp \
		&& git fetch --depth 1 origin tag $(LLAMA_CPP_TAG) \
		&& git checkout $(LLAMA_CPP_TAG)

.PHONY: build-ollama
build-ollama:
	cd ollama && cmake -B build &&  cmake --build build