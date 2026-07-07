# Phase 2 — Repository Setup

## Goal

Turn the Phase 1 architecture scaffold into a runnable local
development environment: version control with a real branch strategy,
CI validation of what already exists, consistent formatting rules, and
a local Nakama + PostgreSQL + Redis stack that Phase 3 can connect to.

## What Was Built

1. **Git initialized** on `main`, with Phase 1 as its own commit and
   Phase 2 developed on `phase/2-repository-setup` per the branch
   strategy in `CONTRIBUTING.md`.
2. **`.editorconfig`** — consistent indentation/charset rules across
   GDScript (tabs, per Godot convention), TypeScript, SQL, YAML, and
   Markdown.
3. **CI skeleton** (`.github/workflows/ci.yml`) with four jobs, each
   validating something that actually exists today (no placeholder
   jobs):
   - `.editorconfig` compliance
   - Godot project headless import check (`client/`)
   - `docker compose config` validation
   - SQL migration apply-test against a throwaway CI Postgres
   A server-module build/test job is intentionally deferred to Phase 5
   — `tools/build-scripts/build_server_modules.sh` already handles the
   "no modules yet" case cleanly for local use in the meantime.
4. **Local Docker Compose stack** (`infra/docker/`): Postgres 16,
   Redis 7, and Nakama 3.21, with:
   - Two databases auto-created in the same Postgres instance:
     `nakama` (Nakama's internal schema) and `warzone` (our game data)
   - `server/modules/` mounted read-only into the Nakama container so
     Phase 5+ module code is picked up without image rebuilds
   - `.env.example` template; real `.env` gitignored
5. **First Postgres migration** for the `warzone` database
   (`0001_init_accounts_and_nicknames`), implementing the account/
   nickname split decided in ADR-0002, including the case-insensitive
   uniqueness index on nicknames and length/charset constraints.
6. **Build/migration scripts** (`tools/build-scripts/`):
   `migrate_warzone_db.sh`, `build_server_modules.sh`,
   `export_client.sh` — all real, runnable scripts with explicit,
   actionable failure messages for preconditions not yet met (e.g. no
   export presets configured until Phase 13), rather than silent
   no-ops.

## Corrections Made This Phase

- `project.godot` had been placed at the repository root in Phase 1,
  inconsistent with `ARCHITECTURE.md` defining `client/` as the Godot
  project root. Folded the fix into the Phase 1 commit before
  branching, so history stays clean rather than needing a follow-up
  "oops" commit.

## Explicitly Out of Scope This Phase

- Any actual `ServiceContainer`/`EventBus` code (Phase 3)
- Any Nakama custom RPC modules (Phase 4/5)
- Production/staging infrastructure (`infra/k8s/`) — deferred to
  Phase 13 per the original architecture decision to avoid premature
  infra complexity

## Testing Checklist

- [ ] `git log --oneline` on `main` shows the Phase 1 commit; `phase/2-repository-setup` branches from it
- [ ] `docker compose -f infra/docker/docker-compose.yml config -q` runs with no errors after copying `.env.example` → `.env`
- [ ] `docker compose up -d` from `infra/docker/` brings up Postgres, Redis, and Nakama with all healthchecks passing
- [ ] Nakama Console reachable at `http://localhost:7351`
- [ ] `psql` into the `warzone` database and confirm `warzone_accounts` and `warzone_nicknames` tables exist after running migration 0001
- [ ] Attempting to insert two nicknames differing only by case fails on the unique index (manual proof of ADR-2 enforcement)
- [ ] `./tools/build-scripts/build_server_modules.sh` runs and reports "no buildable server modules found yet" without erroring
- [ ] `./tools/build-scripts/export_client.sh Android build/test.apk` fails with the clear "export_presets.cfg does not exist yet" message (expected until Phase 13)
- [ ] CI workflow YAML is syntactically valid (validated via `yaml.safe_load` during this phase)

## Next Milestone

**Phase 3 — Core Framework**: implement `ServiceContainer.gd` (DI) and
`EventBus.gd` as the first real production GDScript in the repo,
registered as the two sanctioned autoloads per `ARCHITECTURE.md` §5,
plus the first unit tests under `client/tests/unit/`.

## Estimated Completion

**~4%** of overall project (Phase 2 of 16 complete).
