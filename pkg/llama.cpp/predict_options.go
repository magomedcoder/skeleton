//go:build llama
// +build llama

package llama

var DefaultOptions PredictOptions = PredictOptions{
	Seed:              -1,
	Threads:           4,
	Tokens:            128,
	Penalty:           1.1,
	Repeat:            64,
	Batch:             512,
	NKeep:             64,
	TopK:              40,
	TopP:              0.95,
	MinP:              0.05,
	TailFreeSamplingZ: 1.0,
	TypicalP:          1.0,
	Temperature:       0.8,
	FrequencyPenalty:  0.0,
	PresencePenalty:   0.0,
	Mirostat:          0,
	MirostatTAU:       5.0,
	MirostatETA:       0.1,
	MMap:              true,
	RopeFreqBase:      10000,
	RopeFreqScale:     1.0,
	XTCProbability:    0.0,
	XTCThreshold:      0.5,
	DRYMultiplier:     0.0,
	DRYBase:           1.75,
	DRYAllowedLength:  2,
	DRYPenaltyLastN:   -1,
	TopNSigma:         0.0,
}

func SetPredictionTensorSplit(maingpu string) PredictOption {
	return func(p *PredictOptions) {
		p.TensorSplit = maingpu
	}
}

func SetPredictionMainGPU(maingpu string) PredictOption {
	return func(p *PredictOptions) {
		p.MainGPU = maingpu
	}
}

func SetRopeFreqBase(rfb float32) PredictOption {
	return func(p *PredictOptions) {
		p.RopeFreqBase = rfb
	}
}

func SetRopeFreqScale(rfs float32) PredictOption {
	return func(p *PredictOptions) {
		p.RopeFreqScale = rfs
	}
}

func SetNDraft(nd int) PredictOption {
	return func(p *PredictOptions) {
		p.NDraft = nd
	}
}

func SetMinP(minp float32) PredictOption {
	return func(p *PredictOptions) {
		p.MinP = minp
	}
}

func SetXTCProbability(prob float32) PredictOption {
	return func(p *PredictOptions) {
		p.XTCProbability = prob
	}
}

func SetXTCThreshold(threshold float32) PredictOption {
	return func(p *PredictOptions) {
		p.XTCThreshold = threshold
	}
}

func SetDRYMultiplier(multiplier float32) PredictOption {
	return func(p *PredictOptions) {
		p.DRYMultiplier = multiplier
	}
}

func SetDRYBase(base float32) PredictOption {
	return func(p *PredictOptions) {
		p.DRYBase = base
	}
}

func SetDRYAllowedLength(length int) PredictOption {
	return func(p *PredictOptions) {
		p.DRYAllowedLength = length
	}
}

func SetDRYPenaltyLastN(n int) PredictOption {
	return func(p *PredictOptions) {
		p.DRYPenaltyLastN = n
	}
}

func SetTopNSigma(n float32) PredictOption {
	return func(p *PredictOptions) {
		p.TopNSigma = n
	}
}

var EnableF16KV PredictOption = func(p *PredictOptions) {
	p.F16KV = true
}

var Debug PredictOption = func(p *PredictOptions) {
	p.DebugMode = true
}

var EnablePromptCacheAll PredictOption = func(p *PredictOptions) {
	p.PromptCacheAll = true
}

var EnablePromptCacheRO PredictOption = func(p *PredictOptions) {
	p.PromptCacheRO = true
}

var IgnoreEOS PredictOption = func(p *PredictOptions) {
	p.IgnoreEOS = true
}

func WithGrammar(s string) PredictOption {
	return func(p *PredictOptions) {
		p.Grammar = s
	}
}

func SetMlock(b bool) PredictOption {
	return func(p *PredictOptions) {
		p.MLock = b
	}
}

func SetMemoryMap(b bool) PredictOption {
	return func(p *PredictOptions) {
		p.MMap = b
	}
}

func SetTokenCallback(fn func(string) bool) PredictOption {
	return func(p *PredictOptions) {
		p.TokenCallback = fn
	}
}

func SetStopWords(stop ...string) PredictOption {
	return func(p *PredictOptions) {
		p.StopPrompts = stop
	}
}

func SetSeed(seed int) PredictOption {
	return func(p *PredictOptions) {
		p.Seed = seed
	}
}

func SetThreads(threads int) PredictOption {
	return func(p *PredictOptions) {
		p.Threads = threads
	}
}

func SetTokens(tokens int) PredictOption {
	return func(p *PredictOptions) {
		p.Tokens = tokens
	}
}

func SetTopK(topk int) PredictOption {
	return func(p *PredictOptions) {
		p.TopK = topk
	}
}

func SetTopP(topp float32) PredictOption {
	return func(p *PredictOptions) {
		p.TopP = topp
	}
}

func SetTemperature(temp float32) PredictOption {
	return func(p *PredictOptions) {
		p.Temperature = temp
	}
}

func SetPathPromptCache(f string) PredictOption {
	return func(p *PredictOptions) {
		p.PathPromptCache = f
	}
}

func SetPenalty(penalty float32) PredictOption {
	return func(p *PredictOptions) {
		p.Penalty = penalty
	}
}

func SetRepeat(repeat int) PredictOption {
	return func(p *PredictOptions) {
		p.Repeat = repeat
	}
}

func SetBatch(size int) PredictOption {
	return func(p *PredictOptions) {
		p.Batch = size
	}
}

func SetNKeep(n int) PredictOption {
	return func(p *PredictOptions) {
		p.NKeep = n
	}
}

func NewPredictOptions(opts ...PredictOption) PredictOptions {
	p := DefaultOptions
	for _, opt := range opts {
		opt(&p)
	}
	return p
}

func SetTailFreeSamplingZ(tfz float32) PredictOption {
	return func(p *PredictOptions) {
		p.TailFreeSamplingZ = tfz
	}
}

func SetTypicalP(tp float32) PredictOption {
	return func(p *PredictOptions) {
		p.TypicalP = tp
	}
}

func SetFrequencyPenalty(fp float32) PredictOption {
	return func(p *PredictOptions) {
		p.FrequencyPenalty = fp
	}
}

func SetPresencePenalty(pp float32) PredictOption {
	return func(p *PredictOptions) {
		p.PresencePenalty = pp
	}
}

func SetMirostat(m int) PredictOption {
	return func(p *PredictOptions) {
		p.Mirostat = m
	}
}

func SetMirostatETA(me float32) PredictOption {
	return func(p *PredictOptions) {
		p.MirostatETA = me
	}
}

func SetMirostatTAU(mt float32) PredictOption {
	return func(p *PredictOptions) {
		p.MirostatTAU = mt
	}
}

func SetPenalizeNL(pnl bool) PredictOption {
	return func(p *PredictOptions) {
		p.PenalizeNL = pnl
	}
}

func SetLogitBias(lb string) PredictOption {
	return func(p *PredictOptions) {
		p.LogitBias = lb
	}
}
