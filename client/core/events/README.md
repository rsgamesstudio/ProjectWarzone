# Event Bus

**Layer:** Core infrastructure
**Status:** Implemented (Phase 3)

## Responsibility

Typed, decoupled publish/subscribe channel for cross-feature
communication (e.g. inventory changes notifying UI, damage events
notifying minimap indicators). This is the ONLY sanctioned channel for
cross-feature communication besides an explicit public service
interface documented in a feature's own README.

## Depends On

- none

## Public Interface

- `GameEvent` — base class every event type extends (`game_event.gd`)
- `EventBus.publish(event: GameEvent) -> void`
- `EventBus.subscribe(event_type: Script, callback: Callable) -> Callable`
- `EventBus.unsubscribe(event_type: Script, callback: Callable) -> void`
- `EventBus.subscriber_count(event_type: Script) -> int`
- `EventBus.clear() -> void` (test teardown only)

## Files

- `game_event.gd` — base class for all event types
- `event_bus.gd` — the pub/sub implementation

## How Features Use This

`EventBus` is not an autoload. A single instance is created by
`Bootstrap` at startup and registered into `Services` under the key
`"EventBus"`. Features resolve it like any other service:

```gdscript
var event_bus: EventBus = Services.resolve("EventBus")
event_bus.subscribe(PlayerDamagedEvent, _on_player_damaged)
```

Each feature defines its own `GameEvent` subclasses inside its own
`domain/` layer (e.g. `PlayerDamagedEvent` inside
`features/character_controller/domain/`) — this core module only
provides the base class and the bus itself, never feature-specific
event types.

## Tests

- `client/tests/unit/core/test_event_bus.gd` (9 cases covering
  delivery, type isolation, unsubscribe, multiple subscribers,
  subscriber_count, clear, and timestamping)
- Test fixture event types live under
  `client/tests/unit/core/fixtures/` and must never be referenced by
  real gameplay code.
