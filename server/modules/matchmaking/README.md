# Matchmaking Module

**Layer:** Nakama server module
**Status:** Not implemented (scheduled: Phase 11)

## Responsibility

Authoritative matchmaking: queues parties in Redis, forms balanced 50-player matches, assigns match handler instances.

## Depends On

- Redis (queue/presence)
- `server/modules/match_handler`

## Public Interface (planned)

- Nakama matchmaker matched-hook
- RPC `enqueue_party(party)`

## Notes

Designed so the matching criteria (skill, region, party size) can evolve without touching client contracts.
