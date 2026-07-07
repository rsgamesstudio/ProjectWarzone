class_name ReplicationManager
extends RefCounted
## Owns one InterpolationBuffer per remote entity (keyed by user ID)
## and feeds them from the snapshot payloads
## NakamaClientAdapter.match_snapshot_received emits. This is the
## piece client/features/character_controller (Phase 6) will query for
## "where should I render this remote player right now" — Phase 5
## only builds the data pipeline, not the actual character rendering.

var _buffers: Dictionary = {} # user_id (String) -> InterpolationBuffer

## Call once per received snapshot (see
## NakamaClientAdapter.match_snapshot_received). `local_user_id` is
## excluded — the local player renders from its own predicted state
## (PredictionBuffer/Reconciler), never from interpolation.
func ingest_snapshot(snapshot: Dictionary, local_user_id: String) -> void:
	if not snapshot.has("players") or not snapshot.has("elapsedSeconds"):
		push_error("ReplicationManager: malformed snapshot payload: %s" % snapshot)
		return

	var timestamp: float = snapshot["elapsedSeconds"]
	for player_data in snapshot["players"]:
		var user_id: String = player_data.get("userId", "")
		if user_id.is_empty() or user_id == local_user_id:
			continue

		if not _buffers.has(user_id):
			_buffers[user_id] = InterpolationBuffer.new()

		var pos: Dictionary = player_data.get("position", {})
		var position := Vector3(pos.get("x", 0.0), pos.get("y", 0.0), pos.get("z", 0.0))
		_buffers[user_id].add_snapshot(timestamp, position)

func get_interpolated_position(user_id: String, render_time_seconds: float) -> Vector3:
	if not _buffers.has(user_id):
		return Vector3.ZERO
	return _buffers[user_id].get_interpolated_position(render_time_seconds)

func has_entity(user_id: String) -> bool:
	return _buffers.has(user_id)

## Removes an entity's buffer entirely — call this on a
## MatchPresenceEvent leave, once that's wired up (Phase 6), so
## disconnected players don't linger in memory for the rest of the match.
func remove_entity(user_id: String) -> void:
	_buffers.erase(user_id)

func tracked_entity_count() -> int:
	return _buffers.size()
