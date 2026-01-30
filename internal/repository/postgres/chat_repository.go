package postgres

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/magomedcoder/legion/internal/domain"
)

type chatSessionRepository struct {
	db *pgxpool.Pool
}

func NewChatSessionRepository(db *pgxpool.Pool) domain.ChatSessionRepository {
	return &chatSessionRepository{db: db}
}

func (r *chatSessionRepository) Create(ctx context.Context, session *domain.ChatSession) error {
	err := r.db.QueryRow(ctx, `
		INSERT INTO chat_sessions (id, user_id, title, model, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id
	`,
		session.Id,
		session.UserId,
		session.Title,
		session.Model,
		session.CreatedAt,
		session.UpdatedAt,
	).Scan(&session.Id)

	return err
}

func (r *chatSessionRepository) GetById(ctx context.Context, id string) (*domain.ChatSession, error) {
	var session domain.ChatSession
	err := r.db.QueryRow(ctx, `
		SELECT id, user_id, title, model, created_at, updated_at, deleted_at
		FROM chat_sessions
		WHERE id = $1 AND deleted_at IS NULL
	`, id).Scan(
		&session.Id,
		&session.UserId,
		&session.Title,
		&session.Model,
		&session.CreatedAt,
		&session.UpdatedAt,
		&session.DeletedAt,
	)

	if err != nil {
		return nil, handleNotFound(err, "сессия не найдена")
	}

	return &session, nil
}

func (r *chatSessionRepository) GetByUserId(ctx context.Context, userID int, page, pageSize int32) ([]*domain.ChatSession, int32, error) {
	_, pageSize, offset := normalizePagination(page, pageSize)

	var total int32
	err := r.db.QueryRow(ctx, `
		SELECT COUNT(*)
		FROM chat_sessions
		WHERE user_id = $1 AND deleted_at IS NULL
	`, userID).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	rows, err := r.db.Query(ctx, `
		SELECT id, user_id, title, model, created_at, updated_at, deleted_at
		FROM chat_sessions
		WHERE user_id = $1 AND deleted_at IS NULL
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`, userID, pageSize, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var sessions []*domain.ChatSession
	for rows.Next() {
		var session domain.ChatSession
		if err := rows.Scan(
			&session.Id,
			&session.UserId,
			&session.Title,
			&session.Model,
			&session.CreatedAt,
			&session.UpdatedAt,
			&session.DeletedAt,
		); err != nil {
			return nil, 0, err
		}
		sessions = append(sessions, &session)
	}

	if rows.Err() != nil {
		return nil, 0, rows.Err()
	}

	return sessions, total, nil
}

func (r *chatSessionRepository) Update(ctx context.Context, session *domain.ChatSession) error {
	session.UpdatedAt = time.Now()
	_, err := r.db.Exec(ctx, `
		UPDATE chat_sessions
		SET title = $2, model = $3, updated_at = $4
		WHERE id = $1 AND deleted_at IS NULL
	`,
		session.Id,
		session.Title,
		session.Model,
		session.UpdatedAt,
	)

	return err
}

func (r *chatSessionRepository) Delete(ctx context.Context, id string) error {
	_, err := r.db.Exec(ctx, `
		UPDATE chat_sessions
		SET deleted_at = NOW()
		WHERE id = $1 AND deleted_at IS NULL
	`, id)

	return err
}
