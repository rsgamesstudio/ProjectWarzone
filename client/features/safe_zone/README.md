# Safe Zone

**Layer:** Client feature module
**Status:** Not implemented (scheduled: Phase 10)

## Responsibility

Client rendering and countdown UI for the shrinking safe zone; authoritative zone state/timing computed server-side.

## Depends On

- `client/features/minimap`
- `client/networking/nakama_client`

## Public Interface (planned)

- `SafeZoneService.current_zone`
- signal `zone_phase_changed`

## Notes

Zone math (center drift, radius shrink schedule) lives server-side in server/modules/match_handler.
