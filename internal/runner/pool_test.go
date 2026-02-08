package runner

import (
	"context"
	"testing"
)

func TestNewPool(t *testing.T) {
	p := NewPool(nil)
	if p == nil {
		t.Fatal("NewPool(nil) не должен возвращать nil")
	}

	runners := p.GetRunners()
	if len(runners) != 0 {
		t.Errorf("новый пул должен иметь 0 раннеров, получено %d", len(runners))
	}

	if p.HasActiveRunners() {
		t.Error("новый пул не должен иметь активных раннеров")
	}
}

func TestNewPool_withAddresses(t *testing.T) {
	p := NewPool([]string{"a:1", "b:2"})
	runners := p.GetRunners()
	if len(runners) != 2 {
		t.Errorf("ожидалось 2 раннера, получено %d", len(runners))
	}

	if !p.HasActiveRunners() {
		t.Error("ожидалось HasActiveRunners true")
	}
}

func TestPool_Add_Remove(t *testing.T) {
	p := NewPool([]string{"a:1"})
	p.Add("b:2")

	runners := p.GetRunners()
	if len(runners) != 2 {
		t.Errorf("после Add: ожидалось 2 раннера, получено %d", len(runners))
	}

	p.Remove("a:1")

	runners = p.GetRunners()
	if len(runners) != 1 {
		t.Errorf("после Remove: ожидался 1 раннер, получено %d", len(runners))
	}

	if runners[0].Address != "b:2" {
		t.Errorf("оставшийся адрес: %s", runners[0].Address)
	}
}

func TestPool_Add_emptyIgnored(t *testing.T) {
	p := NewPool(nil)
	p.Add("")
	
	if len(p.GetRunners()) != 0 {
		t.Error("Add с пустым адресом не должен добавлять")
	}
}

func TestPool_SetRunnerEnabled(t *testing.T) {
	p := NewPool([]string{"a:1"})
	if !p.HasActiveRunners() {
		t.Error("ожидался активный раннер до отключения")
	}

	p.SetRunnerEnabled("a:1", false)
	if p.HasActiveRunners() {
		t.Error("ожидалось отсутствие активных после отключения")
	}

	runners := p.GetRunners()
	if len(runners) != 1 || runners[0].Enabled {
		t.Errorf("раннер должен быть отключён: %+v", runners)
	}

	p.SetRunnerEnabled("a:1", true)
	if !p.HasActiveRunners() {
		t.Error("ожидался активный раннер после включения")
	}
}

func TestPool_CheckConnection_noRunners(t *testing.T) {
	p := NewPool(nil)
	ok, err := p.CheckConnection(context.Background())
	if err == nil {
		t.Error("ожидалась ошибка при отсутствии раннеров")
	}

	if ok {
		t.Error("ожидалось false")
	}
}
