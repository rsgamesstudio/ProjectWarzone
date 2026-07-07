extends Node
## Autoload name: `Services`
##
## Minimal service locator / DI container. Features register their
## public services here at bootstrap and resolve dependencies here
## instead of hardcoding scene-tree paths across feature boundaries.
## See ARCHITECTURE.md §5 for the rationale.
##
## This is intentionally one of only two true Godot autoloads in the
## project (the other being Bootstrap). Every other cross-cutting
## system — EventBus, save system, network client, etc. — registers
## itself into this container rather than becoming its own autoload,
## so it can be swapped for a test double in isolation.
##
## Usage:
##
##     Services.register("EventBus", my_event_bus_instance)
##     var bus: EventBus = Services.resolve("EventBus")
##
## Registering under a key that is already taken raises a pushed error
## and refuses to overwrite by default, to catch accidental
## double-registration bugs early. Pass `allow_override = true`
## explicitly for the rare legitimate case (e.g. swapping in a test
## double during an automated test's setup).

var _services: Dictionary = {}

## Registers `instance` under `key`. Fails (logs an error, does not
## register) if `key` is already registered unless `allow_override`
## is true.
func register(key: String, instance: Variant, allow_override: bool = false) -> void:
	if _services.has(key) and not allow_override:
		push_error("Services: '%s' is already registered. Pass allow_override=true if this is intentional (e.g. test setup)." % key)
		return
	_services[key] = instance

## Resolves the service registered under `key`. Returns null and logs
## an error if nothing is registered under that key — callers in
## production code should treat a null return as a startup ordering
## bug, not a condition to silently branch around.
func resolve(key: String) -> Variant:
	if not _services.has(key):
		push_error("Services: nothing registered under '%s'. Check autoload/registration order." % key)
		return null
	return _services[key]

## Returns whether something is currently registered under `key`,
## without the error-logging side effect of resolve(). Useful for
## optional dependencies.
func has_service(key: String) -> bool:
	return _services.has(key)

## Removes a registration. Intended for test teardown; avoid in normal
## gameplay code, since other features may hold resolved references
## already and won't be notified.
func unregister(key: String) -> void:
	_services.erase(key)

## Clears every registration. Intended for automated test isolation
## between test cases — never called from gameplay code.
func clear_all() -> void:
	_services.clear()

## Returns the keys currently registered. Intended for startup logging
## and debugging tools — do not use as a substitute for resolve() in
## gameplay logic.
func registered_keys() -> Array:
	return _services.keys()
