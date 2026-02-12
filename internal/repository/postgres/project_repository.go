package postgres

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/magomedcoder/legion/internal/domain"
	"github.com/magomedcoder/legion/pkg"
	"gorm.io/gorm"
)

type projectRepository struct {
	db *gorm.DB
}

func NewProjectRepository(db *gorm.DB) domain.ProjectRepository {
	return &projectRepository{db: db}
}

func (r *projectRepository) Create(ctx context.Context, project *domain.Project) error {
	m := &ProjectModel{
		Name:      project.Name,
		CreatedBy: project.CreatedBy,
	}
	if err := r.db.WithContext(ctx).Create(m).Error; err != nil {
		return err
	}

	project.Id = m.Id.String()

	return nil
}

func (r *projectRepository) GetById(ctx context.Context, id string) (*domain.Project, error) {
	parsed, err := uuid.Parse(id)
	if err != nil {
		return nil, errors.New("проект не найден")
	}

	var m ProjectModel
	if err := r.db.WithContext(ctx).Where("id = ?", parsed).First(&m).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, pkg.HandleNotFound(err, "проект не найден")
		}

		return nil, err
	}

	return &domain.Project{
		Id:        m.Id.String(),
		Name:      m.Name,
		CreatedBy: m.CreatedBy,
	}, nil
}

func (r *projectRepository) ListByUser(ctx context.Context, userId int, page, pageSize int32) ([]*domain.Project, int32, error) {
	_, pageSize, offset := normalizePagination(page, pageSize)

	subQuery := r.db.WithContext(ctx).Model(&ProjectMemberModel{}).
		Select("project_id").
		Where("user_id = ?", userId)

	var total int64
	if err := r.db.WithContext(ctx).Model(&ProjectModel{}).
		Where("id IN (?)", subQuery).
		Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var list []ProjectModel
	if err := r.db.WithContext(ctx).Where("id IN (?)", subQuery).
		Order("created_at DESC").
		Offset(int(offset)).
		Limit(int(pageSize)).
		Find(&list).Error; err != nil {
		return nil, 0, err
	}

	projects := make([]*domain.Project, 0, len(list))
	for _, m := range list {
		projects = append(projects, &domain.Project{
			Id:        m.Id.String(),
			Name:      m.Name,
			CreatedBy: m.CreatedBy,
		})
	}

	return projects, int32(total), nil
}
