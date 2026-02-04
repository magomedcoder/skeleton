package llama

type ModelOptions struct {
	ContextSize   int
	Seed          int
	NBatch        int
	F16Memory     bool
	MLock         bool
	MMap          bool
	LowVRAM       bool
	Embeddings    bool
	NUMA          bool
	NGPULayers    int
	MainGPU       string
	TensorSplit   string
	FreqRopeBase  float32
	FreqRopeScale float32
	LoraBase      string
	LoraAdapter   string
}

type PredictOptions struct {
	Seed, Threads, Tokens, TopK, Repeat, Batch, NKeep int
	TopP, MinP, Temperature, Penalty                  float32
	NDraft                                            int
	F16KV                                             bool
	DebugMode                                         bool
	StopPrompts                                       []string
	IgnoreEOS                                         bool
	TailFreeSamplingZ                                 float32
	TypicalP                                          float32
	FrequencyPenalty                                  float32
	PresencePenalty                                   float32
	Mirostat                                          int
	MirostatETA                                       float32
	MirostatTAU                                       float32
	PenalizeNL                                        bool
	LogitBias                                         string
	TokenCallback                                     func(string) bool
	PathPromptCache                                   string
	MLock, MMap, PromptCacheAll                       bool
	PromptCacheRO                                     bool
	Grammar                                           string
	MainGPU                                           string
	TensorSplit                                       string
	RopeFreqBase                                      float32
	RopeFreqScale                                     float32
	XTCProbability                                    float32
	XTCThreshold                                      float32
	DRYMultiplier                                     float32
	DRYBase                                           float32
	DRYAllowedLength                                  int
	DRYPenaltyLastN                                   int
	TopNSigma                                         float32
}

type PredictOption func(p *PredictOptions)

type ModelOption func(p *ModelOptions)
