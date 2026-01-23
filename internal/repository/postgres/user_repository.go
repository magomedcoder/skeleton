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
		INSERT INTO users (email, password, name, created_at)
		VALUES ($1, $2, $3, $4)
		RETURNING id
	`,
		user.Email,
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
		SELECT id, email, password, name, created_at
		FROM users
		WHERE id = $1
	`, id).Scan(
		&user.Id,
		&user.Email,
		&user.Password,
		&user.Name,
		&user.CreatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("пользователь не найден")
		}
		return nil, err
	}

	return &user, nil
}

func (u *userRepository) GetByEmail(ctx context.Context, email string) (*domain.User, error) {
	var user domain.User
	err := u.db.QueryRow(ctx,
		`
		SELECT id, email, password, name, created_at
		FROM users
		WHERE email = $1
	`, email).Scan(
		&user.Id,
		&user.Email,
		&user.Password,
		&user.Name,
		&user.CreatedAt,
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
		SET email = $2, password = $3, name = $4
		WHERE id = $1
	`,
		user.Id,
		user.Email,
		user.Password,
		user.Name,
	)

	return err
}
