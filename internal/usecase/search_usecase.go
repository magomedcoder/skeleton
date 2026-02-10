package usecase

import (
	"context"
	"strings"

	"github.com/magomedcoder/legion/internal/domain"
)

type SearchUseCase struct {
	userRepo domain.UserRepository
}

func NewSearchUseCase(userRepo domain.UserRepository) *SearchUseCase {
	return &SearchUseCase{
		userRepo: userRepo,
	}
}

func (s *SearchUseCase) SearchUsers(ctx context.Context, query string, page, pageSize int32) ([]*domain.User, int32, error) {
	query = strings.TrimSpace(query)
	if query == "" {
		return []*domain.User{}, 0, nil
	}

	users, total, err := s.userRepo.Search(ctx, query, page, pageSize)
	if err != nil {
		return nil, 0, err
	}
	for _, user := range users {
		user.Password = ""
	}
	return users, total, nil
}
