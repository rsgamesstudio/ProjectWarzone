class_name GutFixtureEventA
extends GameEvent
## Test-only event type used by test_event_bus.gd. Not a real gameplay
## event — real events live inside their owning feature's domain/
## layer. Kept under tests/ so it can never be mistaken for one.

var payload: String

func _init(p_payload: String = "") -> void:
	super()
	payload = p_payload
