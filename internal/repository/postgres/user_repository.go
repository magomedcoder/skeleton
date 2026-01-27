package postgres

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/magomedcoder/legion/internal/domain"
)

type userRepository struct {
	db *pgx.Conn
}

func NewUserRepository(db *pgx.Conn) domain.UserRepository {
	return &userRepository{db: db}
}

func (u *userRepository) Create(ctx context.Context, user *domain.User) error {
	err := u.db.QueryRow(ctx,
		`
		INSERT INTO users (username, password, name, created_at)
		VALUES ($1, $2, $3, $4)
		RETURNING id
	`,
		user.Username,
		user.Password,
		user.Name,
		user.CreatedAt,
	).Scan(&user.Id)

	return err
}

func (u *userRepository) GetById(ctx context.Context, id int) (*domain.User, error) {
	var user domain.User
	err := u.db.QueryRow(ctx,
		`
		SELECT id, username, password, name, created_at, deleted_at
		FROM users
		WHERE id = $1 AND deleted_at IS NULL
	`, id).Scan(
		&user.Id,
		&user.Username,
		&user.Password,
		&user.Name,
		&user.CreatedAt,
		&user.DeletedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("пользователь не найден")
		}
		return nil, err
	}

	return &user, nil
}

func (u *userRepository) GetByUsername(ctx context.Context, username string) (*domain.User, error) {
	var user domain.User
	err := u.db.QueryRow(ctx,
		`
		SELECT id, username, password, name, created_at, deleted_at
		FROM users
		WHERE username = $1 AND deleted_at IS NULL
	`, username).Scan(
		&user.Id,
		&user.Username,
		&user.Password,
		&user.Name,
		&user.CreatedAt,
		&user.DeletedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("пользователь не найден")
		}
		return nil, err
	}

	return &user, nil
}

func (u *userRepository) Update(ctx context.Context, user *domain.User) error {
	_, err := u.db.Exec(ctx,
		`
		UPDATE users
		SET username = $2, password = $3, name = $4, updated_at = NOW()
		WHERE id = $1 AND deleted_at IS NULL
	`,
		user.Id,
		user.Username,
		user.Password,
		user.Name,
	)

	return err
}
