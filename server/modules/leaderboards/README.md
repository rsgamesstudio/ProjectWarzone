# Leaderboards Module

**Layer:** Nakama server module
**Status:** Not implemented (scheduled: Phase 9)

## Responsibility

Configures and updates Nakama's built-in leaderboard records for seasonal/global/friend boards.

## Depends On

- Nakama built-in leaderboard API
- PostgreSQL (season definitions)

## Public Interface (planned)

- hook: match end -> leaderboard record submission

## Notes

Reuses Nakama primitives rather than a bespoke ranking system to reduce maintenance surface.
