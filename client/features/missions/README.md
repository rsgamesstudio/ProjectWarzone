# Missions

**Layer:** Client feature module
**Status:** Not implemented (scheduled: Phase 9/ongoing)

## Responsibility

Daily/weekly mission display, progress tracking, seasonal progression UI.

## Depends On

- `client/networking/nakama_client`

## Public Interface (planned)

- `MissionService.active_missions`
- signal `mission_progress_updated`
- signal `mission_completed`

## Notes

Progress computation is server-authoritative; client only renders state pushed from server.
