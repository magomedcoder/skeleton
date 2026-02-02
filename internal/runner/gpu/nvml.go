//go:build nvidia

package gpu

import (
	"fmt"

	"github.com/NVIDIA/go-nvml/pkg/nvml"
	"github.com/magomedcoder/legion/pkg/logger"
)

type nvmlCollector struct {
	initDone bool
}

func NewCollector() Collector {
	ret := nvml.Init()
	if ret != nvml.SUCCESS {
		logger.D("gpu: инициализация NVML не удалась: %s (нет NVIDIA GPU или драйвера)", ret)
		return &nvmlCollector{initDone: false}
	}

	return &nvmlCollector{initDone: true}
}

func (c *nvmlCollector) Collect() []Info {
	if !c.initDone {
		return nil
	}

	count, ret := nvml.DeviceGetCount()
	if ret != nvml.SUCCESS {
		logger.D("gpu: получение количества устройств: %s", ret)
		return nil
	}
	if count <= 0 {
		return nil
	}

	out := make([]Info, 0, count)
	for i := 0; i < count; i++ {
		device, ret := nvml.DeviceGetHandleByIndex(i)
		if ret != nvml.SUCCESS {
			continue
		}

		info := c.collectDevice(device)
		if info != nil {
			out = append(out, *info)
		}
	}

	return out
}

func (c *nvmlCollector) collectDevice(device nvml.Device) *Info {
	info := &Info{}

	if name, ret := nvml.DeviceGetName(device); ret == nvml.SUCCESS {
		info.Name = name
	} else {
		info.Name = fmt.Sprintf("GPU %d", device)
	}

	if temp, ret := nvml.DeviceGetTemperature(device, nvml.TEMPERATURE_GPU); ret == nvml.SUCCESS {
		info.TemperatureC = int32(temp)
	}

	if mem, ret := nvml.DeviceGetMemoryInfo(device); ret == nvml.SUCCESS {
		info.MemoryTotalMB = mem.Total / (1024 * 1024)
		info.MemoryUsedMB = mem.Used / (1024 * 1024)
	}

	if util, ret := nvml.DeviceGetUtilizationRates(device); ret == nvml.SUCCESS {
		info.UtilizationPercent = util.Gpu
	}

	return info
}
