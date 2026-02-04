package llama

var DefaultModelOptions ModelOptions = ModelOptions{
	ContextSize:   512,
	Seed:          0,
	F16Memory:     false,
	MLock:         false,
	Embeddings:    false,
	MMap:          true,
	LowVRAM:       false,
	NBatch:        512,
	FreqRopeBase:  10000,
	FreqRopeScale: 1.0,
}

func SetLoraBase(s string) ModelOption {
	return func(p *ModelOptions) {
		p.LoraBase = s
	}
}

func SetLoraAdapter(s string) ModelOption {
	return func(p *ModelOptions) {
		p.LoraAdapter = s
	}
}

func SetContext(c int) ModelOption {
	return func(p *ModelOptions) {
		p.ContextSize = c
	}
}

func WithRopeFreqBase(f float32) ModelOption {
	return func(p *ModelOptions) {
		p.FreqRopeBase = f
	}
}

func WithRopeFreqScale(f float32) ModelOption {
	return func(p *ModelOptions) {
		p.FreqRopeScale = f
	}
}

func SetModelSeed(c int) ModelOption {
	return func(p *ModelOptions) {
		p.Seed = c
	}
}

func SetMMap(b bool) ModelOption {
	return func(p *ModelOptions) {
		p.MMap = b
	}
}

func SetNBatch(n_batch int) ModelOption {
	return func(p *ModelOptions) {
		p.NBatch = n_batch
	}
}

func SetTensorSplit(maingpu string) ModelOption {
	return func(p *ModelOptions) {
		p.TensorSplit = maingpu
	}
}

func SetMainGPU(maingpu string) ModelOption {
	return func(p *ModelOptions) {
		p.MainGPU = maingpu
	}
}

func SetGPULayers(n int) ModelOption {
	return func(p *ModelOptions) {
		p.NGPULayers = n
	}
}

var EnabelLowVRAM ModelOption = func(p *ModelOptions) {
	p.LowVRAM = true
}

var EnableNUMA ModelOption = func(p *ModelOptions) {
	p.NUMA = true
}

var EnableEmbeddings ModelOption = func(p *ModelOptions) {
	p.Embeddings = true
}

var EnableF16Memory ModelOption = func(p *ModelOptions) {
	p.F16Memory = true
}

var EnableMLock ModelOption = func(p *ModelOptions) {
	p.MLock = true
}

func NewModelOptions(opts ...ModelOption) ModelOptions {
	p := DefaultModelOptions
	for _, opt := range opts {
		opt(&p)
	}
	return p
}
