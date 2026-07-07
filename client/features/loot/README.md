# Loot Spawning

**Layer:** Client feature module
**Status:** Not implemented (scheduled: Phase 10)

## Responsibility

Client-side rendering of loot spawns, pickup interaction, air drop visuals/markers.

## Depends On

- `client/features/inventory`
- `client/features/minimap`

## Public Interface (planned)

- `LootService.request_pickup(loot_id)`

## Notes

Spawn tables and RNG are server-authoritative (server/modules/match_handler) to prevent client-side loot prediction exploits.
