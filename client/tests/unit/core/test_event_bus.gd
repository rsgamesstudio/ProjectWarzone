extends GutTest
## Unit tests for client/core/events/event_bus.gd.

var EventBusScript: Script = preload("res://core/events/event_bus.gd")
var bus: EventBus

# Tracks calls made by the test double subscriber below.
var _received_events: Array = []

func before_each() -> void:
	bus = EventBusScript.new()
	_received_events.clear()

func _record(event: GameEvent) -> void:
	_received_events.append(event)

func test_subscriber_receives_published_event_of_matching_type() -> void:
	bus.subscribe(GutFixtureEventA, _record)

	var event := GutFixtureEventA.new("hello")
	bus.publish(event)

	assert_eq(_received_events.size(), 1, "subscriber should be called exactly once")
	assert_eq(_received_events[0].payload, "hello", "the exact event instance should be passed through")

func test_subscriber_does_not_receive_unrelated_event_type() -> void:
	bus.subscribe(GutFixtureEventA, _record)

	bus.publish(GutFixtureEventB.new())

	assert_eq(_received_events.size(), 0, "a subscriber to type A must not be invoked for type B")

func test_publish_with_no_subscribers_does_not_error() -> void:
	# Should simply be a no-op; the test passes if no exception/assert
	# failure is raised.
	bus.publish(GutFixtureEventA.new("nobody listening"))
	assert_true(true)

func test_unsubscribe_stops_further_delivery() -> void:
	var callback := Callable(self, "_record")
	bus.subscribe(GutFixtureEventA, callback)
	bus.unsubscribe(GutFixtureEventA, callback)

	bus.publish(GutFixtureEventA.new("should not arrive"))

	assert_eq(_received_events.size(), 0)

func test_multiple_subscribers_all_receive_event() -> void:
	var second_bus_hits: Array = []
	var second_callback := func(event: GameEvent) -> void:
		second_bus_hits.append(event)

	bus.subscribe(GutFixtureEventA, _record)
	bus.subscribe(GutFixtureEventA, second_callback)

	bus.publish(GutFixtureEventA.new("broadcast"))

	assert_eq(_received_events.size(), 1)
	assert_eq(second_bus_hits.size(), 1)

func test_subscriber_count_reflects_active_subscriptions() -> void:
	assert_eq(bus.subscriber_count(GutFixtureEventA), 0)

	var callback := Callable(self, "_record")
	bus.subscribe(GutFixtureEventA, callback)
	assert_eq(bus.subscriber_count(GutFixtureEventA), 1)

	bus.unsubscribe(GutFixtureEventA, callback)
	assert_eq(bus.subscriber_count(GutFixtureEventA), 0)

func test_clear_removes_all_subscriptions() -> void:
	bus.subscribe(GutFixtureEventA, _record)
	bus.clear()

	bus.publish(GutFixtureEventA.new("post-clear"))

	assert_eq(_received_events.size(), 0)

func test_event_has_timestamp_set_on_construction() -> void:
	var event := GutFixtureEventA.new("t")
	assert_gt(event.timestamp, -1.0, "timestamp should be populated by GameEvent._init")
