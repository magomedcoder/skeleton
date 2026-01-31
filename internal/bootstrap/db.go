package bootstrap

import (
	"context"
	"errors"
	"fmt"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"net/url"
	"strings"
)

func CheckDatabase(ctx context.Context, dsn string) error {
	targetDB, baseDSN, err := parseDSN(dsn)
	if err != nil {
		return fmt.Errorf("ошибка парсинга DSN: %w", err)
	}

	postgresDSN := baseDSN + "/postgres"
	pool, err := pgxpool.New(ctx, postgresDSN)
	if err != nil {
		return fmt.Errorf("ошибка подключения к postgres: %w", err)
	}
	defer pool.Close()

	if err := pool.Ping(ctx); err != nil {
		return fmt.Errorf("ошибка проверки соединения с postgres: %w", err)
	}

	var exists int
	if err = pool.QueryRow(ctx, "SELECT 1 FROM pg_database WHERE datname = $1", targetDB).Scan(&exists); err == nil {
		return nil
	}

	if !errors.Is(err, pgx.ErrNoRows) {
		return fmt.Errorf("ошибка проверки существования БД: %w", err)
	}

	_, err = pool.Exec(ctx, fmt.Sprintf("CREATE DATABASE %s", quoteIdentifier(targetDB)))
	if err != nil {
		return fmt.Errorf("ошибка создания базы данных %s: %w", targetDB, err)
	}

	return nil
}

func parseDSN(dsn string) (string, string, error) {
	u, err := url.Parse(dsn)
	if err != nil {
		return "", "", err
	}

	dbName := strings.TrimPrefix(u.Path, "/")
	if dbName == "" {
		return "", "", fmt.Errorf("имя базы данных не указано в DSN")
	}

	u.Path = ""
	baseDSN := u.String()
	if !strings.HasSuffix(baseDSN, "//") {
		baseDSN = strings.TrimSuffix(baseDSN, "/")
	}
	baseDSN += "/"

	return dbName, baseDSN, nil
}

func quoteIdentifier(name string) string {
	return `"` + strings.ReplaceAll(name, `"`, `""`) + `"`
}
