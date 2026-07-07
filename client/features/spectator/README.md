# Spectator Mode

**Layer:** Client feature module
**Status:** Not implemented (scheduled: Phase 10+)

## Responsibility

Post-elimination and dedicated spectator camera system, player cycling, free-cam within replay-safe bounds.

## Depends On

- `client/networking/replication`
- `client/features/character_controller`

## Public Interface (planned)

- `SpectatorController.follow(player_id)`
- `SpectatorController.free_cam()`

## Notes

Built to share entity-state reading with the future replay system (architecture reserved, not implemented).
