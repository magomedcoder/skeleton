package mappers

import (
	"testing"

	"github.com/magomedcoder/legion/internal/domain"
)

func TestUserToProto_nil(t *testing.T) {
	if got := UserToProto(nil); got != nil {
		t.Errorf("UserToProto(nil) = %v, ожидалось nil", got)
	}
}

func TestUserToProto(t *testing.T) {
	u := &domain.User{
		Id:       1,
		Username: "test1",
		Name:     "Test1",
		Surname:  "Test1",
		Role:     domain.UserRoleAdmin,
	}
	got := UserToProto(u)
	if got == nil {
		t.Fatal("ожидался непустой результат")
	}

	if got.Id != "1" || got.Username != "test1" || got.Name != "Test1" || got.Surname != "Test1" || got.Role != 1 {
		t.Errorf("UserToProto: неверные поля %+v", got)
	}
}
