class_name PredictionBuffer
extends RefCounted
## Records the local player's predicted position at each simulation
## tick, keyed by tick number, so `Reconciler` can later replay
## unacknowledged input once a server snapshot arrives. Pure data
## structure — no engine/network dependency, fully unit-testable.
##
## Usage:
##   var buffer := PredictionBuffer.new()
##   buffer.record(tick, predicted_position, input_delta)
##   ...
##   var entry = buffer.get_entry(tick)
##   buffer.discard_up_to(acknowledged_tick)

class Entry:
	var tick: int
	var position: Vector3
	var input_delta: Vector3 # the movement delta that produced `position`, for replay

	func _init(p_tick: int, p_position: Vector3, p_input_delta: Vector3) -> void:
		tick = p_tick
		position = p_position
		input_delta = p_input_delta

## Bound on how many ticks of history to retain even if never
## explicitly discarded, so a stalled/missing server snapshot can't
## make this buffer grow unboundedly and leak memory over a long
## match.
const MAX_ENTRIES: int = 600 # at 10 ticks/sec (see MATCH_TICK_RATE), 60 seconds of history

var _entries: Dictionary = {} # tick (int) -> Entry
var _ordered_ticks: Array[int] = []

func record(tick: int, position: Vector3, input_delta: Vector3) -> void:
	if not _entries.has(tick):
		_ordered_ticks.append(tick)
	_entries[tick] = Entry.new(tick, position, input_delta)

	while _ordered_ticks.size() > MAX_ENTRIES:
		var oldest: int = _ordered_ticks.pop_front()
		_entries.erase(oldest)

func get_entry(tick: int) -> Entry:
	return _entries.get(tick, null)

func has_entry(tick: int) -> bool:
	return _entries.has(tick)

## Returns every recorded entry with tick > `after_tick`, in
## chronological order — exactly the set of inputs that need to be
## replayed after correcting to a server snapshot at `after_tick`.
func get_entries_after(after_tick: int) -> Array[Entry]:
	var result: Array[Entry] = []
	for tick in _ordered_ticks:
		if tick > after_tick:
			result.append(_entries[tick])
	return result

## Discards all entries at or before `tick` — call this once a server
## snapshot at `tick` has been fully processed and reconciled, since
## that history is no longer needed for replay.
func discard_up_to(tick: int) -> void:
	while not _ordered_ticks.is_empty() and _ordered_ticks[0] <= tick:
		var oldest: int = _ordered_ticks.pop_front()
		_entries.erase(oldest)

func size() -> int:
	return _ordered_ticks.size()
