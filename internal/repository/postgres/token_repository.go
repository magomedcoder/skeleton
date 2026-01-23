package postgres

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/magomedcoder/legion/internal/domain"
)

type tokenRepository struct {
	db *pgx.Conn
}

func NewTokenRepository(db *pgx.Conn) domain.TokenRepository {
	return &tokenRepository{db: db}
}

func (u *tokenRepository) Create(ctx context.Context, token *domain.Token) error {
	err := u.db.QueryRow(ctx,
		`
		INSERT INTO tokens (user_id, token, type, expires_at, created_at)
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

func (u *tokenRepository) GetByToken(ctx context.Context, token string) (*domain.Token, error) {
	var t domain.Token
	err := u.db.QueryRow(ctx,
		`
		SELECT id, user_id, token, type, expires_at, created_at
		FROM tokens
		WHERE token = $1
	`, token).Scan(
		&t.Id,
		&t.UserId,
		&t.Token,
		&t.Type,
		&t.ExpiresAt,
		&t.CreatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("токен не найден")
		}
		return nil, err
	}

	return &t, nil
}

func (u *tokenRepository) DeleteByToken(ctx context.Context, token string) error {
	_, err := u.db.Exec(ctx, `DELETE FROM tokens WHERE token = $1`, token)
	return err
}

func (u *tokenRepository) DeleteByUserId(ctx context.Context, userID int, tokenType domain.TokenType) error {
	_, err := u.db.Exec(ctx, `DELETE FROM tokens WHERE user_id = $1 AND type = $2`, userID, tokenType)
	return err
}
