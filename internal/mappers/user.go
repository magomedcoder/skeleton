package mappers

import (
	"strconv"

	"github.com/magomedcoder/legion/api/pb/commonpb"
	"github.com/magomedcoder/legion/internal/domain"
)

func UserToProto(user *domain.User) *commonpb.User {
	if user == nil {
		return nil
	}

	return &commonpb.User{
		Id:       strconv.Itoa(user.Id),
		Username: user.Username,
		Name:     user.Name,
		Surname:  user.Surname,
		Role:     int32(user.Role),
	}
}
