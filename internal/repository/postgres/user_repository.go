package postgres

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/magomedcoder/skeleton/internal/domain"
)

type userRepository struct {
	db *pgxpool.Pool
}

func NewUserRepository(db *pgxpool.Pool) domain.UserRepository {
	return &userRepository{db: db}
}

func (u *userRepository) Create(ctx context.Context, user *domain.User) error {
	err := u.db.QueryRow(ctx,
		`
		INSERT INTO users (username, password, name, surname, role, created_at)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id
	`,
		user.Username,
		user.Password,
		user.Name,
		user.Surname,
		int16(user.Role),
		user.CreatedAt,
	).Scan(&user.Id)

	return err
}

func (u *userRepository) UpdateLastVisitedAt(ctx context.Context, userID int) error {
	_, err := u.db.Exec(ctx,
		`UPDATE users SET last_visited_at = NOW() WHERE id = $1 AND deleted_at IS NULL`,
		userID,
	)
	return err
}

func (u *userRepository) GetById(ctx context.Context, id int) (*domain.User, error) {
	var user domain.User
	var role int16
	err := u.db.QueryRow(ctx,
		`
		SELECT id, username, password, name, surname, role, created_at, last_visited_at, deleted_at
		FROM users
		WHERE id = $1 AND deleted_at IS NULL
	`, id).Scan(
		&user.Id,
		&user.Username,
		&user.Password,
		&user.Name,
		&user.Surname,
		&role,
		&user.CreatedAt,
		&user.LastVisitedAt,
		&user.DeletedAt,
	)

	if err != nil {
		return nil, handleNotFound(err, "пользователь не найден")
	}

	user.Role = domain.UserRole(role)

	return &user, nil
}

func (u *userRepository) GetByUsername(ctx context.Context, username string) (*domain.User, error) {
	var user domain.User
	var role int16
	err := u.db.QueryRow(ctx,
		`
		SELECT id, username, password, name, surname, role, created_at, last_visited_at, deleted_at
		FROM users
		WHERE username = $1 AND deleted_at IS NULL
	`, username).Scan(
		&user.Id,
		&user.Username,
		&user.Password,
		&user.Name,
		&user.Surname,
		&role,
		&user.CreatedAt,
		&user.LastVisitedAt,
		&user.DeletedAt,
	)
	if err != nil {
		return nil, handleNotFound(err, "пользователь не найден")
	}

	user.Role = domain.UserRole(role)

	return &user, nil
}

func (u *userRepository) Update(ctx context.Context, user *domain.User) error {
	_, err := u.db.Exec(ctx,
		`
		UPDATE users SET
		    username = $2,
		    password = CASE WHEN $3 = '' THEN password ELSE $3 END,
		    name = $4,
		    surname = $5,
		    role = $6,
		    updated_at = NOW()
		WHERE id = $1 AND deleted_at IS NULL
	`,
		user.Id,
		user.Username,
		user.Password,
		user.Name,
		user.Surname,
		int16(user.Role),
	)

	return err
}

func (u *userRepository) List(ctx context.Context, page, pageSize int32) ([]*domain.User, int32, error) {
	_, pageSize, offset := normalizePagination(page, pageSize)

	var total int32
	if err := u.db.QueryRow(ctx, `
		SELECT COUNT(*) FROM users 
		WHERE deleted_at IS NULL
	`).Scan(&total); err != nil {
		return nil, 0, err
	}

	rows, err := u.db.Query(ctx,
		`
		SELECT id, username, password, name, surname, role, created_at, last_visited_at, deleted_at
		FROM users
		WHERE deleted_at IS NULL
		ORDER BY id DESC
		LIMIT $1 OFFSET $2
	`, pageSize, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	users := make([]*domain.User, 0)
	for rows.Next() {
		var user domain.User
		var role int16
		if err := rows.Scan(
			&user.Id,
			&user.Username,
			&user.Password,
			&user.Name,
			&user.Surname,
			&role,
			&user.CreatedAt,
			&user.LastVisitedAt,
			&user.DeletedAt,
		); err != nil {
			return nil, 0, err
		}
		user.Role = domain.UserRole(role)
		users = append(users, &user)
	}
	if rows.Err() != nil {
		return nil, 0, rows.Err()
	}

	return users, total, nil
}
