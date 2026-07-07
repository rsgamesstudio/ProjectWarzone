# Redis Usage

**Layer:** Data layer
**Status:** Not implemented (scheduled: Phase 2/11)

## Responsibility

Ephemeral/high-throughput data: matchmaking queue, live presence, session cache, daily mission reset timers.

## Depends On

- none

## Public Interface (planned)

- key namespace conventions documented here once Phase 2 stack is running

## Notes

Nothing stored in Redis is treated as durable; PostgreSQL is always the fallback source of truth.
