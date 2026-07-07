# Admin API

**Layer:** Backend service
**Status:** Not implemented (scheduled: Phase 14+)

## Responsibility

Internal tooling API for support/ops: player lookup, ban/unban, report review, content updates.

## Depends On

- PostgreSQL
- `server/modules/anti_cheat`

## Public Interface (planned)

- REST endpoints, auth-gated to internal roles only

## Notes

Not player-facing; scheduled late since it depends on enough live data existing to be useful.
