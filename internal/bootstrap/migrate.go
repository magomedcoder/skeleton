package bootstrap

import (
	"context"
	"embed"
	"errors"
	"fmt"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"sort"
	"strings"
)

func RunMigrations(ctx context.Context, pool *pgxpool.Pool, fs embed.FS) error {
	if err := ensureSchemaMigrations(ctx, pool); err != nil {
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

		applied, err := isMigrationApplied(ctx, pool, version)
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
			if err := markMigrationApplied(ctx, pool, version); err != nil {
				return fmt.Errorf("запись версии %s: %w", version, err)
			}
			continue
		}

		if _, err := pool.Exec(ctx, sql); err != nil {
			return fmt.Errorf("выполнение миграции %s: %w", version, err)
		}
		if err := markMigrationApplied(ctx, pool, version); err != nil {
			return fmt.Errorf("запись версии %s: %w", version, err)
		}
	}

	return nil
}

func ensureSchemaMigrations(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := pool.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS schema_migrations (
			version TEXT PRIMARY KEY,
			applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
		)
	`)
	return err
}

func isMigrationApplied(ctx context.Context, pool *pgxpool.Pool, version string) (bool, error) {
	var n int
	err := pool.QueryRow(ctx, "SELECT 1 FROM schema_migrations WHERE version = $1", version).Scan(&n)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, nil
		}
		return false, err
	}
	return true, nil
}

func markMigrationApplied(ctx context.Context, pool *pgxpool.Pool, version string) error {
	_, err := pool.Exec(ctx, "INSERT INTO schema_migrations (version) VALUES ($1)", version)
	return err
}
