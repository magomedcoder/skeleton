package postgres

import (
	"context"
	"errors"

	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/pkg"
	"gorm.io/gorm"
)

type userRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) domain.UserRepository {
	return &userRepository{db: db}
}

func (u *userRepository) Create(ctx context.Context, user *domain.User) error {
	m := userDomainToModel(user)
	if err := u.db.WithContext(ctx).Create(m).Error; err != nil {
		return err
	}
	user.Id = m.Id
	return nil
}

func (u *userRepository) UpdateLastVisitedAt(ctx context.Context, userID int) error {
	return u.db.WithContext(ctx).Model(&userModel{}).
		Where("id = ?", userID).
		Update("last_visited_at", gorm.Expr("NOW()")).Error
}

func (u *userRepository) GetById(ctx context.Context, id int) (*domain.User, error) {
	var m userModel
	err := u.db.WithContext(ctx).Where("id = ?", id).First(&m).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, pkg.HandleNotFound(err, "пользователь не найден")
		}
		return nil, err
	}

	return userModelToDomain(&m), nil
}

func (u *userRepository) GetByUsername(ctx context.Context, username string) (*domain.User, error) {
	var m userModel
	err := u.db.WithContext(ctx).Where("username = ?", username).First(&m).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, pkg.HandleNotFound(err, "пользователь не найден")
		}
		return nil, err
	}
	return userModelToDomain(&m), nil
}

func (u *userRepository) Update(ctx context.Context, user *domain.User) error {
	updates := map[string]interface{}{
		"username":   user.Username,
		"name":       user.Name,
		"surname":    user.Surname,
		"role":       int32(user.Role),
		"updated_at": gorm.Expr("NOW()"),
	}

	if user.Password != "" {
		updates["password"] = user.Password
	}

	return u.db.WithContext(ctx).Model(&userModel{}).
		Where("id = ?", user.Id).
		Updates(updates).Error
}

func (u *userRepository) List(ctx context.Context, page, pageSize int32) ([]*domain.User, int32, error) {
	_, pageSize, offset := normalizePagination(page, pageSize)

	var total int64
	if err := u.db.WithContext(ctx).Model(&userModel{}).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var list []userModel
	if err := u.db.WithContext(ctx).Order("id DESC").Limit(int(pageSize)).Offset(int(offset)).
		Find(&list).Error; err != nil {
		return nil, 0, err
	}

	users := make([]*domain.User, 0, len(list))
	for i := range list {
		users = append(users, userModelToDomain(&list[i]))
	}
	return users, int32(total), nil
}

func (u *userRepository) Search(ctx context.Context, query string, page, pageSize int32) ([]*domain.User, int32, error) {
	_, pageSize, offset := normalizePagination(page, pageSize)

	q := "%" + query + "%"

	var total int64
	if err := u.db.WithContext(ctx).
		Model(&userModel{}).
		Where("username ILIKE ? OR name ILIKE ? OR surname ILIKE ?", q, q, q).
		Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var list []userModel
	if err := u.db.WithContext(ctx).
		Where("username ILIKE ? OR name ILIKE ? OR surname ILIKE ?", q, q, q).
		Order("id DESC").
		Limit(int(pageSize)).
		Offset(int(offset)).
		Find(&list).Error; err != nil {
		return nil, 0, err
	}

	users := make([]*domain.User, 0, len(list))
	for i := range list {
		users = append(users, userModelToDomain(&list[i]))
	}

	return users, int32(total), nil
}
