package runner

import (
	"bufio"
	"os"
	"runtime"
	"strconv"
	"strings"
)

type SysInfo struct {
	Hostname      string
	OS            string
	Arch          string
	CPUCores      int32
	MemoryTotalMB uint64
}

func CollectSysInfo() SysInfo {
	info := SysInfo{
		OS:       runtime.GOOS,
		Arch:     runtime.GOARCH,
		CPUCores: int32(runtime.NumCPU()),
	}
	if h, err := os.Hostname(); err == nil {
		info.Hostname = h
	}

	info.MemoryTotalMB = memoryTotalMB()

	return info
}

func memoryTotalMB() uint64 {
	f, err := os.Open("/proc/meminfo")
	if err != nil {
		return 0
	}
	defer f.Close()

	sc := bufio.NewScanner(f)
	for sc.Scan() {
		line := sc.Text()
		if !strings.HasPrefix(line, "MemTotal:") {
			continue
		}

		fields := strings.Fields(line)
		if len(fields) < 2 {
			return 0
		}

		kb, err := strconv.ParseUint(fields[1], 10, 64)
		if err != nil {
			return 0
		}

		return kb / 1024
	}

	return 0
}
