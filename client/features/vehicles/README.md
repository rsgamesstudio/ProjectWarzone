# Vehicles

**Layer:** Client feature module
**Status:** Not implemented (scheduled: Phase 10+)

## Responsibility

Drivable vehicle controllers, entry/exit, networked vehicle physics reconciliation, fuel/damage state.

## Depends On

- `client/features/character_controller`
- `client/networking/prediction`

## Public Interface (planned)

- `VehicleController.enter(player_id)`
- `VehicleController.exit()`

## Notes

Vehicle physics prediction reuses the same reconciliation pipeline as player movement.
