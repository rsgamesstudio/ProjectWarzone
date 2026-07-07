class_name GutFixtureEventB
extends GameEvent
## A second, distinct test-only event type — used to prove EventBus
## only invokes subscribers registered for the exact event type
## published, not for unrelated GameEvent subclasses.

func _init() -> void:
	super()
