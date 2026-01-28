package postgres

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/magomedcoder/legion/internal/domain"
)

type messageRepository struct {
	db *pgxpool.Pool
}

func NewMessageRepository(db *pgxpool.Pool) domain.MessageRepository {
	return &messageRepository{db: db}
}

func (r *messageRepository) Create(ctx context.Context, message *domain.Message) error {
	err := r.db.QueryRow(ctx, `
		INSERT INTO messages (id, session_id, content, role, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id
	`,
		message.Id,
		message.SessionId,
		message.Content,
		message.Role,
		message.CreatedAt,
		message.UpdatedAt,
	).Scan(&message.Id)

	return err
}

func (r *messageRepository) GetBySessionId(ctx context.Context, sessionID string, page, pageSize int32) ([]*domain.Message, int32, error) {
	_, pageSize, offset := normalizePagination(page, pageSize)

	var total int32
	err := r.db.QueryRow(ctx, `
		SELECT COUNT(*)
		FROM messages
		WHERE session_id = $1 AND deleted_at IS NULL
	`, sessionID).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	rows, err := r.db.Query(ctx, `
		SELECT id, session_id, content, role, created_at, updated_at, deleted_at
		FROM messages
		WHERE session_id = $1 AND deleted_at IS NULL
		ORDER BY created_at ASC
		LIMIT $2 OFFSET $3
	`, sessionID, pageSize, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var messages []*domain.Message
	for rows.Next() {
		var message domain.Message
		if err := rows.Scan(
			&message.Id,
			&message.SessionId,
			&message.Content,
			&message.Role,
			&message.CreatedAt,
			&message.UpdatedAt,
			&message.DeletedAt,
		); err != nil {
			return nil, 0, err
		}
		messages = append(messages, &message)
	}

	if rows.Err() != nil {
		return nil, 0, rows.Err()
	}

	return messages, total, nil
}
