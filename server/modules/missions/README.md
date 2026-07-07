# Missions Module

**Layer:** Nakama server module
**Status:** Not implemented (scheduled: Phase 9)

## Responsibility

Tracks daily/weekly mission progress and seasonal progression server-side based on match events.

## Depends On

- PostgreSQL (mission definitions/progress)
- Redis (daily reset scheduling)

## Public Interface (planned)

- RPC `get_missions()`
- internal hook: match event -> mission progress update

## Notes

Mission definitions are data-driven content rows, not hardcoded logic, to allow live content updates.
