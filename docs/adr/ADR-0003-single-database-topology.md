# ADR-0003: Single Postgres Database for Nakama + Custom Game Tables

**Status:** Accepted (supersedes part of ADR-0001/Phase 2 setup)
**Date:** 2026-07-04

## Context

Phase 2 provisioned two separate databases in the local Postgres
container: `nakama` (Nakama's internal schema) and `warzone` (intended
for our custom tables like `warzone_accounts`/`warzone_nicknames` from
ADR-0002).

While implementing Phase 4 (Authentication), this turned out to be
broken: Nakama's TypeScript/Go runtime modules read/write custom SQL
exclusively through `nk.sqlQuery`/`nk.sqlExec`, which execute against
the **single Postgres connection Nakama itself was started with**.
PostgreSQL does not support cross-database queries without extensions
like `postgres_fdw`/`dblink`, which we are not introducing solely to
work around a self-inflicted schema split. A Nakama runtime module
therefore has no way to reach a second, separate `warzone` database.

## Decision

Consolidate everything into **one Postgres database** — the same one
Nakama's own schema lives in (named `nakama` in local dev, per
`infra/docker/docker-compose.yml`). Our custom tables use the
`warzone_` prefix specifically so they're visually and structurally
distinct from Nakama's own internal tables (`users`, `storage`,
`leaderboard`, etc.) inside that shared database, and so a future
`\dt warzone_*` is enough to see "our" schema at a glance.

This is also simply the standard, documented pattern for Nakama
projects — custom relational tables are expected to live alongside
Nakama's own schema in its database, accessed via the runtime's SQL
functions.

## Consequences

- `infra/docker/docker-compose.yml` simplified: a single `POSTGRES_DB`
  (`nakama`), no init script needed to create a second database, no
  `postgres/init-databases.sh`.
- `server/db/postgres/migrations/` now applies against the `nakama`
  database. `tools/build-scripts/migrate_warzone_db.sh` updated
  accordingly. The **migration tool itself remains separate from
  Nakama's own `nakama migrate` command** — golang-migrate manages our
  `warzone_*` tables; Nakama's own migrate command manages its
  internal schema. They coexist safely in one database because they
  operate on disjoint table namespaces.
- `ARCHITECTURE.md` §7 (Data Ownership) updated to reflect a single
  Postgres instance/database rather than two.
- No data existed yet in the `warzone` database (Phase 2 only created
  the empty schema), so there is no migration/backfill concern — this
  is a pre-launch correction, not a production migration.

## Lesson

This is exactly the kind of mistake the phase-by-phase workflow is
meant to catch before it compounds: Phase 2 documented a plausible-
looking design that was never exercised by real code until Phase 4
tried to use it. Per project rules ("refactor when necessary"), it's
fixed here rather than carried forward or patched around.
