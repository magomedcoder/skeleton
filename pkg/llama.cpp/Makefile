.PHONY: test clean

INCLUDE_PATH := $(abspath ./)
LIBRARY_PATH := $(abspath ./)

ifndef UNAME_S
UNAME_S := $(shell uname -s)
endif

ifndef UNAME_P
UNAME_P := $(shell uname -p)
endif

ifndef UNAME_M
UNAME_M := $(shell uname -m)
endif

CCV := $(shell $(CC) --version | head -n 1)
CXXV := $(shell $(CXX) --version | head -n 1)

BUILD_TYPE?=

LLAMA_LIB = llama_lib
CFLAGS   = -I./$(LLAMA_LIB) -I./$(LLAMA_LIB)/include -I./$(LLAMA_LIB)/ggml/include -I. -O3 -DNDEBUG -std=c11 -fPIC
CXXFLAGS = -I./$(LLAMA_LIB) -I./$(LLAMA_LIB)/include -I./$(LLAMA_LIB)/ggml/include -I. -I./$(LLAMA_LIB)/common -I./common -O3 -DNDEBUG -std=c++17 -fPIC
LDFLAGS  =

CFLAGS   += -Wall -Wextra -Wpedantic -Wcast-qual -Wdouble-promotion -Wshadow -Wstrict-prototypes -Wpointer-arith -Wno-unused-function
CXXFLAGS += -Wall -Wextra -Wpedantic -Wcast-qual -Wno-unused-function

ifeq ($(UNAME_S),Linux)
	CFLAGS   += -pthread
	CXXFLAGS += -pthread
endif

GGML_CUDA_OBJ_PATH=CMakeFiles/ggml.dir/ggml-cuda.cu.o

ifeq ($(UNAME_M),$(filter $(UNAME_M),x86_64 i686))
	CFLAGS += -march=native -mtune=native
endif

ifneq ($(filter ppc64%,$(UNAME_M)),)
	POWER9_M := $(shell grep "POWER9" /proc/cpuinfo)
	ifneq (,$(findstring POWER9,$(POWER9_M)))
		CFLAGS += -mcpu=power9
		CXXFLAGS += -mcpu=power9
	endif

	ifeq ($(UNAME_M),ppc64)
		CXXFLAGS += -std=c++23 -DGGML_BIG_ENDIAN
	endif
endif

ifdef LLAMA_GPROF
	CFLAGS   += -pg
	CXXFLAGS += -pg
endif

ifneq ($(filter aarch64%,$(UNAME_M)),)
	CFLAGS += -mcpu=native
	CXXFLAGS += -mcpu=native
endif

ifeq ($(BUILD_TYPE),blis)
	EXTRA_LIBS=
	CMAKE_ARGS+=-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=FLAME
endif

ifeq ($(BUILD_TYPE),cublas)
	EXTRA_LIBS=
	CMAKE_ARGS+=-DLLAMA_CUBLAS=ON
	EXTRA_TARGETS+=$(LLAMA_LIB)/ggml-cuda.o
endif

ifeq ($(BUILD_TYPE),clblas)
	EXTRA_LIBS=
	CMAKE_ARGS+=-DLLAMA_CLBLAST=ON
	EXTRA_TARGETS+=$(LLAMA_LIB)/ggml-opencl.o
endif

ifdef CLBLAST_DIR
	CMAKE_ARGS+=-DCLBlast_dir=$(CLBLAST_DIR)
endif

ifeq ($(GPU_TESTS),true)
	CGO_LDFLAGS="-lcublas -lcudart -L/usr/local/cuda/lib64/"
	TEST_LABEL=gpu
else
	TEST_LABEL=!gpu
endif

$(info I llama_lib build info: )
$(info I UNAME_S:  $(UNAME_S))
$(info I UNAME_P:  $(UNAME_P))
$(info I UNAME_M:  $(UNAME_M))
$(info I CFLAGS:   $(CFLAGS))
$(info I CXXFLAGS: $(CXXFLAGS))
$(info I CGO_LDFLAGS:  $(CGO_LDFLAGS))
$(info I LDFLAGS:  $(LDFLAGS))
$(info I BUILD_TYPE:  $(BUILD_TYPE))
$(info I CMAKE_ARGS:  $(CMAKE_ARGS))
$(info I EXTRA_TARGETS:  $(EXTRA_TARGETS))
$(info I CC:       $(CCV))
$(info I CXX:      $(CXXV))
$(info )

build/build_complete:
	mkdir -p build
	cd build && CC="$(CC)" CXX="$(CXX)" cmake ../$(LLAMA_LIB) $(CMAKE_ARGS) \
		-DLLAMA_CURL=OFF \
		-DLLAMA_BUILD_TESTS=OFF \
		-DLLAMA_BUILD_EXAMPLES=OFF \
		-DCMAKE_POSITION_INDEPENDENT_CODE=ON \
		-DBUILD_SHARED_LIBS=OFF \
		-DGGML_OPENMP=ON
	cd build && VERBOSE=1 cmake --build . --config Release
	touch build/build_complete

llama.o: build/build_complete
	$(CXX) $(CXXFLAGS) -I./$(LLAMA_LIB) -I./$(LLAMA_LIB)/include -I./$(LLAMA_LIB)/common llama.cpp -o llama.o -c $(LDFLAGS)

libllama.a: llama.o build/build_complete
	@mkdir -p obj_temp
	@counter=0; \
	for f in $$(find build -name "*.o" -type f); do \
		counter=$$((counter + 1)); \
		cp "$$f" "obj_temp/$${counter}_$$(basename $$f)"; \
	done
	@cp llama.o obj_temp/
	ar rcs libllama.a obj_temp/*.o
	@rm -rf obj_temp
