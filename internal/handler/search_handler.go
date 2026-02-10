package handler

import (
	"context"

	"github.com/magomedcoder/legion/api/pb/commonpb"
	"github.com/magomedcoder/legion/api/pb/searchpb"
	"github.com/magomedcoder/legion/internal/mappers"
	"github.com/magomedcoder/legion/internal/middleware"
	"github.com/magomedcoder/legion/internal/usecase"
	"github.com/magomedcoder/legion/pkg"
	error2 "github.com/magomedcoder/legion/pkg/error"
	"github.com/magomedcoder/legion/pkg/logger"
	"google.golang.org/grpc/codes"
)

type SearchHandler struct {
	searchpb.UnimplementedSearchServiceServer
	searchUseCase *usecase.SearchUseCase
	authUseCase   usecase.TokenValidator
}

func NewSearchHandler(searchUseCase *usecase.SearchUseCase, authUseCase usecase.TokenValidator) *SearchHandler {
	return &SearchHandler{
		searchUseCase: searchUseCase,
		authUseCase:   authUseCase,
	}
}

func (h *SearchHandler) Users(ctx context.Context, req *searchpb.SearchUsersRequest) (*searchpb.SearchUsersResponse, error) {
	if _, err := middleware.GetUserFromContext(ctx, h.authUseCase); err != nil {
		return nil, err
	}

	logger.D("SearchHandler: поиск пользователей query=%q page=%d", req.Query, req.Page)

	page, pageSize := pkg.NormalizePagination(req.Page, req.PageSize, 20)

	users, total, err := h.searchUseCase.SearchUsers(ctx, req.Query, page, pageSize)
	if err != nil {
		logger.E("SearchHandler: ошибка поиска пользователей: %v", err)
		return nil, error2.ToStatusError(codes.Internal, err)
	}

	resp := &searchpb.SearchUsersResponse{
		Users:    make([]*commonpb.User, 0, len(users)),
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}
	for _, u := range users {
		resp.Users = append(resp.Users, mappers.UserToProto(u))
	}

	return resp, nil
}
