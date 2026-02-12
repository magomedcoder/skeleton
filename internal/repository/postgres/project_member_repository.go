package postgres

import (
	"context"

	"github.com/google/uuid"
	"github.com/magomedcoder/legion/internal/domain"
	"gorm.io/gorm"
)

type projectMemberRepository struct {
	db *gorm.DB
}

func NewProjectMemberRepository(db *gorm.DB) domain.ProjectMemberRepository {
	return &projectMemberRepository{db: db}
}

func (r *projectMemberRepository) Add(ctx context.Context, projectId string, userId int, createdBy int) error {
	parsed, err := uuid.Parse(projectId)
	if err != nil {
		return err
	}

	m := &ProjectMemberModel{
		ProjectId: parsed,
		UserId:    userId,
		CreatedBy: createdBy,
	}

	return r.db.WithContext(ctx).Create(m).Error
}

func (r *projectMemberRepository) GetByProjectId(ctx context.Context, projectId string) ([]int, error) {
	parsed, err := uuid.Parse(projectId)
	if err != nil {
		return nil, err
	}

	var list []ProjectMemberModel
	if err := r.db.WithContext(ctx).Where("project_id = ?", parsed).Find(&list).Error; err != nil {
		return nil, err
	}

	userIds := make([]int, 0, len(list))
	for _, m := range list {
		userIds = append(userIds, m.UserId)
	}

	return userIds, nil
}

func (r *projectMemberRepository) IsMember(ctx context.Context, projectId string, userId int) (bool, error) {
	parsed, err := uuid.Parse(projectId)
	if err != nil {
		return false, err
	}

	var count int64
	err = r.db.WithContext(ctx).Model(&ProjectMemberModel{}).
		Where("project_id = ? AND user_id = ?", parsed, userId).
		Count(&count).Error
	if err != nil {
		return false, err
	}

	return count > 0, nil
}
