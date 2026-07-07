class_name EventBus
extends RefCounted
## Decoupled publish/subscribe channel for cross-feature communication.
##
## This is the ONLY sanctioned channel for a feature to communicate
## with another feature it does not explicitly own a reference to
## (see ARCHITECTURE.md §4 and CODING_STANDARDS.md). Direct scene-tree
## reach-across between feature folders (e.g.
## `get_node("../../OtherFeature")`) is not permitted.
##
## EventBus is NOT an autoload itself — a single instance is created by
## Bootstrap at startup and registered into the ServiceContainer under
## the key "EventBus". Features resolve it via:
##
##     var event_bus: EventBus = Services.resolve("EventBus")
##     event_bus.subscribe(PlayerDamagedEvent, _on_player_damaged)
##     event_bus.publish(PlayerDamagedEvent.new("player_123", 25))
##
## Subscriptions are keyed by the event's GDScript (its class), obtained
## via `event.get_script()`. Passing a raw script reference (not an
## instance) is required for the `event_type` argument to subscribe()/
## unsubscribe() — pass the class itself, e.g. `PlayerDamagedEvent`,
## not `PlayerDamagedEvent.new()`.

## event_type_script -> Array[Callable]
var _subscribers: Dictionary = {}

## Publishes an event to every subscriber registered for its exact
## script type. Subscribers are invoked synchronously, in subscription
## order. A subscriber callback throwing is intentionally NOT caught
## here — bugs in event handlers should surface loudly during
## development rather than being silently swallowed.
func publish(event: GameEvent) -> void:
	var event_type: Script = event.get_script()
	if not _subscribers.has(event_type):
		return
	# Iterate a shallow copy so a subscriber unsubscribing itself
	# during handling doesn't mutate the array we're iterating.
	var callbacks: Array = _subscribers[event_type].duplicate()
	for callback: Callable in callbacks:
		callback.call(event)

## Registers `callback` to be invoked whenever an event of exactly
## `event_type` (a GameEvent subclass, passed as the class/script
## itself) is published. Returns the callback for convenient storage
## if the caller wants to unsubscribe later.
func subscribe(event_type: Script, callback: Callable) -> Callable:
	if not _subscribers.has(event_type):
		_subscribers[event_type] = []
	if not _subscribers[event_type].has(callback):
		_subscribers[event_type].append(callback)
	return callback

## Removes a previously registered subscription. Safe to call even if
## the callback was never subscribed (no-op).
func unsubscribe(event_type: Script, callback: Callable) -> void:
	if not _subscribers.has(event_type):
		return
	_subscribers[event_type].erase(callback)
	if _subscribers[event_type].is_empty():
		_subscribers.erase(event_type)

## Removes every subscription for every event type. Intended for test
## teardown and full scene resets (e.g. returning to main menu), not
## for casual use mid-session.
func clear() -> void:
	_subscribers.clear()

## Returns how many active subscribers exist for `event_type`. Mainly
## useful for tests and debugging tools.
func subscriber_count(event_type: Script) -> int:
	if not _subscribers.has(event_type):
		return 0
	return _subscribers[event_type].size()
