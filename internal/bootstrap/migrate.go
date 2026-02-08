package bootstrap

import (
	"context"
	"embed"
	"fmt"
	"sort"
	"strings"

	"gorm.io/gorm"
)

func RunMigrations(ctx context.Context, db *gorm.DB, fs embed.FS) error {
	if err := ensureSchemaMigrations(ctx, db); err != nil {
		return fmt.Errorf("инициализация таблицы миграций: %w", err)
	}

	migrationsDir := "migrations/postgres"
	entries, err := fs.ReadDir(migrationsDir)
	if err != nil {
		return fmt.Errorf("чтение каталога миграций: %w", err)
	}

	var names []string
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".sql") {
			continue
		}
		names = append(names, e.Name())
	}
	sort.Strings(names)

	for _, name := range names {
		version := name
		path := migrationsDir + "/" + name

		applied, err := isMigrationApplied(ctx, db, version)
		if err != nil {
			return fmt.Errorf("проверка миграции %s: %w", version, err)
		}
		if applied {
			continue
		}

		content, err := fs.ReadFile(path)
		if err != nil {
			return fmt.Errorf("чтение миграции %s: %w", version, err)
		}
		sql := strings.TrimSpace(string(content))
		if sql == "" {
			if err := markMigrationApplied(ctx, db, version); err != nil {
				return fmt.Errorf("запись версии %s: %w", version, err)
			}
			continue
		}

		if err := db.WithContext(ctx).Exec(sql).Error; err != nil {
			return fmt.Errorf("выполнение миграции %s: %w", version, err)
		}
		if err := markMigrationApplied(ctx, db, version); err != nil {
			return fmt.Errorf("запись версии %s: %w", version, err)
		}
	}

	return nil
}

func ensureSchemaMigrations(ctx context.Context, db *gorm.DB) error {
	return db.WithContext(ctx).Exec(`
		CREATE TABLE IF NOT EXISTS schema_migrations (
			version TEXT PRIMARY KEY,
			applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
		)
	`).Error
}

func isMigrationApplied(ctx context.Context, db *gorm.DB, version string) (bool, error) {
	var count int64
	err := db.WithContext(ctx).Raw("SELECT COUNT(*) FROM schema_migrations WHERE version = ?", version).Scan(&count).Error
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func markMigrationApplied(ctx context.Context, db *gorm.DB, version string) error {
	return db.WithContext(ctx).Exec("INSERT INTO schema_migrations (version) VALUES (?)", version).Error
}
