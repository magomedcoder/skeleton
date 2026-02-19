package bootstrap

import (
	"context"
	"fmt"
	"net/url"
	"strings"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func CheckDatabase(ctx context.Context, dsn string) error {
	targetDB, postgresDSN, err := parseDSN(dsn)
	if err != nil {
		return fmt.Errorf("ошибка парсинга DSN: %w", err)
	}

	db, err := gorm.Open(postgres.Open(postgresDSN), &gorm.Config{})
	if err != nil {
		return fmt.Errorf("ошибка подключения к postgres: %w", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		return fmt.Errorf("получение *sql.DB: %w", err)
	}
	defer sqlDB.Close()

	if err := sqlDB.PingContext(ctx); err != nil {
		return fmt.Errorf("ошибка проверки соединения с postgres: %w", err)
	}

	var exists int
	if err := db.Raw("SELECT 1 FROM pg_database WHERE datname = ?", targetDB).Scan(&exists).Error; err != nil {
		return fmt.Errorf("ошибка проверки существования БД: %w", err)
	}
	if exists == 1 {
		return nil
	}

	if err := db.Exec(fmt.Sprintf("CREATE DATABASE %s", quoteIdentifier(targetDB))).Error; err != nil {
		return fmt.Errorf("ошибка создания базы данных %s: %w", targetDB, err)
	}

	return nil
}

func parseDSN(dsn string) (targetDB string, postgresDSN string, err error) {
	if strings.HasPrefix(dsn, "postgres://") || strings.HasPrefix(dsn, "postgresql://") {
		return parseDSNURL(dsn)
	}
	
	return parseDSNLibpq(dsn)
}

func parseDSNLibpq(dsn string) (targetDB string, postgresDSN string, err error) {
	params := make(map[string]string)
	for _, part := range strings.Fields(dsn) {
		if i := strings.Index(part, "="); i > 0 {
			k := strings.TrimSpace(part[:i])
			v := strings.TrimSpace(part[i+1:])
			params[k] = v
		}
	}

	dbname, ok := params["dbname"]
	if !ok || dbname == "" {
		return "", "", fmt.Errorf("имя базы данных не указано в DSN")
	}

	params["dbname"] = "postgres"
	parts := make([]string, 0, len(params))
	for k, v := range params {
		parts = append(parts, k+"="+v)
	}

	return dbname, strings.Join(parts, " "), nil
}

func parseDSNURL(dsn string) (targetDB string, postgresDSN string, err error) {
	u, err := url.Parse(dsn)
	if err != nil {
		return "", "", err
	}

	targetDB = strings.TrimPrefix(u.Path, "/")
	if targetDB == "" {
		return "", "", fmt.Errorf("имя базы данных не указано в DSN")
	}

	u.Path = "/postgres"
	return targetDB, u.String(), nil
}

func quoteIdentifier(name string) string {
	return `"` + strings.ReplaceAll(name, `"`, `""`) + `"`
}
