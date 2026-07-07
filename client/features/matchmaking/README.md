# Matchmaking

**Layer:** Client feature module
**Status:** Not implemented (scheduled: Phase 11)

## Responsibility

Client side of matchmaking: submits party to queue, displays queue state/estimated wait, receives match assignment and triggers scene transition into a match.

## Depends On

- `client/networking/nakama_client`
- `client/features/lobby`

## Public Interface (planned)

- `MatchmakingService.enqueue(party)`
- `MatchmakingService.cancel()`
- signal `match_found(match_id)`

## Notes

Server authority lives in server/modules/matchmaking using Redis-backed queue.
