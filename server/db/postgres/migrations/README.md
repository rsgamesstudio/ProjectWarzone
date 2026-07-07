# PostgreSQL Migrations

**Layer:** Data layer
**Status:** Not implemented (scheduled: Phase 2/4)

## Responsibility

Versioned SQL migrations for all durable data: accounts, nicknames, inventory, stats, match history, mission/season definitions.

## Depends On

- none (source of truth)

## Public Interface (planned)

- sequential numbered migration files, applied via migration tool chosen in Phase 2

## Notes

First migration (Phase 2/4) creates accounts + nicknames tables per ADR-0002.
