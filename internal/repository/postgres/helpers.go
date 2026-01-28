package postgres

import (
	"errors"

	"github.com/jackc/pgx/v5"
)

func normalizePagination(page, pageSize int32) (int32, int32, int32) {
	if page <= 0 {
		page = 1
	}
	if pageSize <= 0 {
		pageSize = 20
	}
	if pageSize > 200 {
		pageSize = 200
	}
	offset := (page - 1) * pageSize
	return page, pageSize, offset
}

func handleNotFound(err error, message string) error {
	if errors.Is(err, pgx.ErrNoRows) {
		return errors.New(message)
	}
	return err
}
