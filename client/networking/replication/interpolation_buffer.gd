class_name InterpolationBuffer
extends RefCounted
## Buffers recent position snapshots for ONE remote entity and
## interpolates between them at render time, rather than teleporting
## the entity to each new snapshot the instant it arrives. Pure
## logic — no engine dependency beyond Vector3, fully unit-testable.
##
## Deliberately renders slightly in the past (see
## INTERPOLATION_DELAY_SECONDS) — this is the standard
## snapshot-interpolation tradeoff: remote entities are always a
## little behind "now" in exchange for smooth motion between sparse
## updates, which is far less noticeable than stutter/teleporting.

class Snapshot:
	var timestamp_seconds: float
	var position: Vector3

	func _init(p_timestamp_seconds: float, p_position: Vector3) -> void:
		timestamp_seconds = p_timestamp_seconds
		position = p_position

## How far in the past to render. Should be at least one server tick
## interval (see MATCH_TICK_RATE server-side) so there are usually two
## snapshots to interpolate between; kept configurable per-instance
## since different entity types (players vs. future vehicles) may
## want different values.
var interpolation_delay_seconds: float = 0.15

var _snapshots: Array[Snapshot] = []

## Bound on retained history — a stalled snapshot stream shouldn't
## leak memory; only recent snapshots are ever relevant for
## interpolation anyway.
const MAX_SNAPSHOTS: int = 30

func add_snapshot(timestamp_seconds: float, position: Vector3) -> void:
	_snapshots.append(Snapshot.new(timestamp_seconds, position))
	# Keep sorted by timestamp defensively — snapshots should already
	# arrive in order, but an out-of-order network delivery shouldn't
	# corrupt interpolation.
	_snapshots.sort_custom(func(a: Snapshot, b: Snapshot) -> bool: return a.timestamp_seconds < b.timestamp_seconds)

	while _snapshots.size() > MAX_SNAPSHOTS:
		_snapshots.pop_front()

## Returns the interpolated position to render at `render_time_seconds`
## (typically "now", in the same clock the snapshots' timestamps use).
## Returns the most recent snapshot's position if there's no pair to
## interpolate between yet (e.g. right after joining a match).
func get_interpolated_position(render_time_seconds: float) -> Vector3:
	if _snapshots.is_empty():
		return Vector3.ZERO

	var target_time: float = render_time_seconds - interpolation_delay_seconds

	if _snapshots.size() == 1:
		return _snapshots[0].position

	if target_time <= _snapshots[0].timestamp_seconds:
		return _snapshots[0].position

	var last_index := _snapshots.size() - 1
	if target_time >= _snapshots[last_index].timestamp_seconds:
		return _snapshots[last_index].position

	for i in range(_snapshots.size() - 1):
		var current: Snapshot = _snapshots[i]
		var next: Snapshot = _snapshots[i + 1]
		if target_time >= current.timestamp_seconds and target_time <= next.timestamp_seconds:
			var span: float = next.timestamp_seconds - current.timestamp_seconds
			var fraction: float = 0.0 if span <= 0.0 else (target_time - current.timestamp_seconds) / span
			return current.position.lerp(next.position, fraction)

	# Unreachable given the boundary checks above, but returning the
	# latest known position is a safe fallback rather than a crash.
	return _snapshots[last_index].position

func snapshot_count() -> int:
	return _snapshots.size()
