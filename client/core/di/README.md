# Dependency Injection

**Layer:** Core infrastructure
**Status:** Implemented (Phase 3)

## Responsibility

Lightweight service locator/container used by every feature to
register and resolve its public services instead of hardcoded
scene-tree lookups. Registered as the `Services` autoload.

## Depends On

- none (root of the dependency graph, alongside `core/autoload`)

## Public Interface

- `Services.register(key: String, instance: Variant, allow_override: bool = false) -> void`
- `Services.resolve(key: String) -> Variant`
- `Services.has_service(key: String) -> bool`
- `Services.unregister(key: String) -> void`
- `Services.clear_all() -> void` (test teardown only)
- `Services.registered_keys() -> Array` (debugging/logging only)

## Files

- `service_container.gd` — the autoload script itself

## Tests

- `client/tests/unit/core/test_service_container.gd` (7 cases: register/resolve, double-registration rejection and override, has_service, unregister, clear_all, registered_keys)
- `client/tests/integration/core/test_bootstrap_integration.gd` verifies the real autoload wiring end-to-end

## Notes

Enables mocking services in unit tests by registering test doubles
before scene load. Registration without `allow_override=true` fails
loudly (pushes an error, does not overwrite) to catch accidental
double-registration bugs early — this was a deliberate design choice
over silently allowing last-write-wins.
