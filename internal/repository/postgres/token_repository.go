package postgres

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/magomedcoder/skeleton/internal/domain"
)

type userSessionRepository struct {
	db *pgxpool.Pool
}

func NewUserSessionRepository(db *pgxpool.Pool) domain.UserSessionRepository {
	return &userSessionRepository{db: db}
}

func (u *userSessionRepository) Create(ctx context.Context, token *domain.Token) error {
	err := u.db.QueryRow(ctx, `
		INSERT INTO user_sessions (user_id, token, type, expires_at, created_at)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id
	`,
		token.UserId,
		token.Token,
		token.Type,
		token.ExpiresAt,
		token.CreatedAt,
	).Scan(&token.Id)

	return err
}

func (u *userSessionRepository) GetByToken(ctx context.Context, token string) (*domain.Token, error) {
	var t domain.Token
	err := u.db.QueryRow(ctx, `
		SELECT id, user_id, token, type, expires_at, created_at, deleted_at
		FROM user_sessions
		WHERE token = $1 AND deleted_at IS NULL
	`, token).Scan(
		&t.Id,
		&t.UserId,
		&t.Token,
		&t.Type,
		&t.ExpiresAt,
		&t.CreatedAt,
		&t.DeletedAt,
	)

	if err != nil {
		return nil, handleNotFound(err, "токен не найден")
	}

	return &t, nil
}

func (u *userSessionRepository) DeleteByToken(ctx context.Context, token string) error {
	_, err := u.db.Exec(ctx, `
		UPDATE user_sessions 
		SET deleted_at = NOW() 
		WHERE token = $1 AND deleted_at IS NULL
	`, token)

	return err
}

func (u *userSessionRepository) DeleteByUserId(ctx context.Context, userID int, tokenType domain.TokenType) error {
	_, err := u.db.Exec(ctx, `
		UPDATE user_sessions 
		SET deleted_at = NOW() 
		WHERE user_id = $1 AND type = $2 AND deleted_at IS NULL
	`, userID, tokenType)

	return err
}

func (u *userSessionRepository) CountByUserIdAndType(ctx context.Context, userID int, tokenType domain.TokenType) (int, error) {
	var count int
	err := u.db.QueryRow(ctx, `
		SELECT COUNT(*) FROM user_sessions
		WHERE user_id = $1 AND type = $2 AND deleted_at IS NULL
	`, userID, tokenType).Scan(&count)

	return count, err
}

func (u *userSessionRepository) DeleteOldestByUserIdAndType(ctx context.Context, userID int, tokenType domain.TokenType, limit int) error {
	if limit <= 0 {
		return nil
	}
	_, err := u.db.Exec(ctx, `
		UPDATE user_sessions SET deleted_at = NOW()
		WHERE id IN (
			SELECT id FROM user_sessions
			WHERE user_id = $1 AND type = $2 AND deleted_at IS NULL
			ORDER BY created_at ASC
			LIMIT $3
		)
	`, userID, tokenType, limit)

	return err
}

func (u *userSessionRepository) ListByUserIdAndType(ctx context.Context, userID int, tokenType domain.TokenType) ([]*domain.Token, error) {
	rows, err := u.db.Query(ctx, `
		SELECT id, user_id, token, type, expires_at, created_at, deleted_at
		FROM user_sessions
		WHERE user_id = $1 AND type = $2 AND deleted_at IS NULL
		ORDER BY created_at DESC
	`, userID, tokenType)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tokens []*domain.Token
	for rows.Next() {
		var t domain.Token
		if err := rows.Scan(&t.Id, &t.UserId, &t.Token, &t.Type, &t.ExpiresAt, &t.CreatedAt, &t.DeletedAt); err != nil {
			return nil, err
		}
		tokens = append(tokens, &t)
	}

	return tokens, rows.Err()
}

func (u *userSessionRepository) DeleteByIdAndUserId(ctx context.Context, id, userID int) error {
	result, err := u.db.Exec(ctx, `
		UPDATE user_sessions
		SET deleted_at = NOW()
		WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
	`, id, userID)
	if err != nil {
		return err
	}

	if result.RowsAffected() == 0 {
		return errors.New("сессия не найдена")
	}

	return nil
}

func (u *userSessionRepository) DeleteRefreshTokensByUserIdExcept(ctx context.Context, userID int, keepRefreshToken string) error {
	_, err := u.db.Exec(ctx, `
		UPDATE user_sessions
		SET deleted_at = NOW()
		WHERE user_id = $1 AND type = $2 AND deleted_at IS NULL AND token != $3
	`,
		userID,
		domain.TokenTypeRefresh,
		keepRefreshToken,
	)

	return err
}
