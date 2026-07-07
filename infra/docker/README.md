# Docker Infrastructure (Local Development)

**Layer:** DevOps
**Status:** Functional local dev stack (Phase 2)

## Responsibility

Provides a local Postgres + Redis + Nakama stack that mirrors the
production topology described in `ARCHITECTURE.md` closely enough for
development and integration testing, without requiring any cloud
account.

## Usage

```bash
cd infra/docker
cp .env.example .env    # edit values, especially passwords
docker compose up -d
```

- Nakama HTTP API: http://localhost:7350
- Nakama gRPC: localhost:7349
- Nakama Console (admin UI): http://localhost:7351 (default login is
  set via `local.yml` — change before anything beyond local dev)
- Postgres: localhost:5432, one database (`nakama` by default — see
  `.env`) holds both Nakama's own internal schema and our `warzone_*`
  custom tables (see `docs/adr/ADR-0003`), applied via
  `server/db/postgres/migrations/`
- Redis: localhost:6379, password-protected via `.env`

## Files

- `docker-compose.yml` — service definitions
- `nakama/local.yml` — local-only Nakama config (dev server key,
  debug logging). **Never reused for production.**
- `.env.example` — template; copy to `.env` (gitignored) before running

## Depends On

- Docker & Docker Compose v2 installed locally

## Notes

Custom Nakama runtime modules (`server/modules/`) are mounted
read-only into the Nakama container so they're picked up without a
rebuild once Phase 5 introduces real module code. As of Phase 2 that
directory is documentation-only (READMEs), so Nakama will start with
no custom RPCs registered — expected until Phase 4/5.
