package postgres

import (
	"context"
	"github.com/jackc/pgx/v5"
	"github.com/magomedcoder/legion/internal/domain"
)

type messageRepository struct {
	db *pgx.Conn
}

func NewMessageRepository(db *pgx.Conn) domain.MessageRepository {
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
	offset := (page - 1) * pageSize

	rows, err := r.db.Query(ctx, `
		SELECT id, session_id, content, role, created_at, updated_at
		FROM messages
		WHERE session_id = $1
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
		); err != nil {
			return nil, 0, err
		}
		messages = append(messages, &message)
	}

	var total int32
	err = r.db.QueryRow(ctx, `
		SELECT COUNT(*)
		FROM messages
		WHERE session_id = $1
	`, sessionID).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	return messages, total, nil
}
