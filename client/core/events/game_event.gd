class_name GameEvent
extends RefCounted
## Base class for all events published on the EventBus.
##
## Feature modules define their own event subclasses (e.g.
## `InventoryChangedEvent`, `MatchFoundEvent`) that extend this class.
## The base class exists so the EventBus can key subscriptions by
## event type (`get_script()`/class name) without every feature having
## to reinvent timestamping or a common supertype.
##
## Usage (in a feature's domain or application layer):
##
##     class_name PlayerDamagedEvent
##     extends GameEvent
##
##     var target_id: String
##     var amount: int
##
##     func _init(p_target_id: String, p_amount: int) -> void:
##         super()
##         target_id = p_target_id
##         amount = p_amount

## Engine time (seconds since startup) the event was constructed.
## Useful for ordering/debugging; not a substitute for server timestamps
## on anything gameplay-authoritative.
var timestamp: float

func _init() -> void:
	timestamp = Time.get_ticks_msec() / 1000.0
