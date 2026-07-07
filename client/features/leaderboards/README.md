# Leaderboards

**Layer:** Client feature module
**Status:** Not implemented (scheduled: Phase 9/ongoing)

## Responsibility

Displays seasonal/global/friend leaderboards sourced from Nakama's leaderboard API.

## Depends On

- `client/networking/nakama_client`

## Public Interface (planned)

- `LeaderboardService.fetch(board_id, page)`

## Notes

Leverages Nakama's built-in leaderboard primitives rather than a custom Postgres query path.
