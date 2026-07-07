# Minimap & Compass

**Layer:** Client feature module
**Status:** Not implemented (scheduled: Phase 9)

## Responsibility

Minimap rendering, compass strip, ping markers, damage direction indicators.

## Depends On

- `client/core/events`
- `client/features/safe_zone`

## Public Interface (planned)

- `MinimapService.add_ping(position, type)`
- `MinimapService.set_zone_data(zone)`

## Notes

Ping system publishes through EventBus so squad UI and voice callouts can both react.
