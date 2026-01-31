package legion

import "embed"

//go:embed migrations/postgres/*.sql
var Postgres embed.FS
