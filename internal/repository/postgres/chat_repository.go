package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/magomedcoder/legion/internal/domain"
)

type chatSessionRepository struct {
	db *pgx.Conn
}

func NewChatSessionRepository(db *pgx.Conn) domain.ChatSessionRepository {
	return &chatSessionRepository{db: db}
}

func (r *chatSessionRepository) Create(ctx context.Context, session *domain.ChatSession) error {
	err := r.db.QueryRow(ctx, `
		INSERT INTO chat_sessions (id, user_id, title, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id
	`,
		session.Id,
		session.UserId,
		session.Title,
		session.CreatedAt,
		session.UpdatedAt,
	).Scan(&session.Id)

	return err
}

func (r *chatSessionRepository) GetById(ctx context.Context, id string) (*domain.ChatSession, error) {
	var session domain.ChatSession
	err := r.db.QueryRow(ctx, `
		SELECT id, user_id, title, created_at, updated_at
		FROM chat_sessions
		WHERE id = $1
	`, id).Scan(
		&session.Id,
		&session.UserId,
		&session.Title,
		&session.CreatedAt,
		&session.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("сессия не найдена")
		}
		return nil, err
	}

	return &session, nil
}

func (r *chatSessionRepository) GetByUserId(ctx context.Context, userID int, page, pageSize int32) ([]*domain.ChatSession, int32, error) {
	offset := (page - 1) * pageSize

	rows, err := r.db.Query(ctx, `
		SELECT id, user_id, title, created_at, updated_at
		FROM chat_sessions
		WHERE user_id = $1
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
			&session.CreatedAt,
			&session.UpdatedAt,
		); err != nil {
			return nil, 0, err
		}
		sessions = append(sessions, &session)
	}

	var total int32
	err = r.db.QueryRow(ctx, `
		SELECT COUNT(*)
		FROM chat_sessions
		WHERE user_id = $1
	`, userID).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	return sessions, total, nil
}

func (r *chatSessionRepository) Update(ctx context.Context, session *domain.ChatSession) error {
	session.UpdatedAt = time.Now()
	_, err := r.db.Exec(ctx, `
		UPDATE chat_sessions
		SET title = $2, updated_at = $3
		WHERE id = $1
	`,
		session.Id,
		session.Title,
		session.UpdatedAt,
	)

	return err
}

func (r *chatSessionRepository) Delete(ctx context.Context, id string) error {
	_, err := r.db.Exec(ctx, `
		DELETE FROM chat_sessions
		WHERE id = $1
	`, id)

	return err
}
