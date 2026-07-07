#!/bin/bash
# Applies (or reverts) SQL migrations for our custom warzone_* tables,
# which live in the SAME Postgres database as Nakama's own internal
# schema (see docs/adr/ADR-0003). This uses golang-migrate and is
# entirely separate from Nakama's own `nakama migrate` command, which
# manages Nakama's internal tables only — the two coexist safely
# because they operate on disjoint table name prefixes.
#
# Requires: https://github.com/golang-migrate/migrate installed locally
# (`brew install golang-migrate` / see their releases page for other OS).
#
# Usage:
#   ./tools/build-scripts/migrate_warzone_db.sh up
#   ./tools/build-scripts/migrate_warzone_db.sh down 1
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MIGRATIONS_DIR="$REPO_ROOT/server/db/postgres/migrations"
ENV_FILE="$REPO_ROOT/infra/docker/.env"

if ! command -v migrate >/dev/null 2>&1; then
    echo "ERROR: 'migrate' CLI not found. Install golang-migrate first:" >&2
    echo "  https://github.com/golang-migrate/migrate#installation" >&2
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: $ENV_FILE not found. Copy infra/docker/.env.example to .env first." >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}?sslmode=disable"

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <up|down|version|force> [N]" >&2
    exit 1
fi

migrate -path "$MIGRATIONS_DIR" -database "$DATABASE_URL" "$@"
