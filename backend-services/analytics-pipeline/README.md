# Analytics Pipeline

**Layer:** Backend service
**Status:** Not implemented (scheduled: Phase 14+)

## Responsibility

Aggregates Firebase Analytics + match event data for retention/engagement/balance analysis.

## Depends On

- Firebase Analytics export
- PostgreSQL (match history)

## Public Interface (planned)

- batch jobs, defined once volume justifies them

## Notes

Read-only relative to gameplay systems; must never be able to influence live match outcomes.
