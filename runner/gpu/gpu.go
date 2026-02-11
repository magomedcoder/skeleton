package gpu

type Info struct {
	Name               string
	TemperatureC       int32
	MemoryTotalMB      uint64
	MemoryUsedMB       uint64
	UtilizationPercent uint32
}

type Collector interface {
	Collect() []Info
}
