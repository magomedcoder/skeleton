package process

import (
	"context"
	"reflect"
	"sync"

	"golang.org/x/sync/errgroup"
)

var startOnce sync.Once

type Process interface {
	Setup(ctx context.Context) error
}

type SubServers struct {
	HealthReporter    *HealthReporter
	MessageSubscriber *MessageSubscriber
}

type Server struct {
	processes []Process
}

func NewServer(servers *SubServers) *Server {
	s := &Server{}
	s.bindProcesses(servers)
	return s
}

func (s *Server) bindProcesses(servers *SubServers) {
	elem := reflect.ValueOf(servers).Elem()
	for i := 0; i < elem.NumField(); i++ {
		if p, ok := elem.Field(i).Interface().(Process); ok {
			s.processes = append(s.processes, p)
		}
	}
}

func (s *Server) Start(eg *errgroup.Group, ctx context.Context) {
	startOnce.Do(func() {
		for _, p := range s.processes {
			proc := p
			eg.Go(func() error { return proc.Setup(ctx) })
		}
	})
}
