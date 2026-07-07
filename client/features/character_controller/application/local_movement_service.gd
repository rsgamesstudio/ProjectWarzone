class_name LocalMovementService
extends RefCounted
## Orchestrates local player movement: computes predicted velocity/
## position each tick (via `MovementCalculator`), records it for later
## reconciliation (`PredictionBuffer`), sends it to the server, and
## reconciles/corrects when a new snapshot arrives. This is the
## "application" layer per ARCHITECTURE.md §3 — it coordinates domain
## logic and the `NakamaClientAdapter`/`ReplicationManager`
## infrastructure, but has no scene-tree/`CharacterBody3D` dependency
## itself, so it's fully testable with fakes.
##
## `character_controller.gd` (presentation) owns one instance of this,
## calls `process_local_tick` from `_physics_process`, and applies the
## returned position to the actual `CharacterBody3D` node.

var _nakama_client: NakamaClientAdapter
var _local_user_id: String
var _prediction_buffer: PredictionBuffer
var _tick_estimator: ServerTickEstimator
var _replication_manager: ReplicationManager

var current_velocity: Vector3 = Vector3.ZERO
var current_position: Vector3 = Vector3.ZERO

func _init(
	nakama_client: NakamaClientAdapter,
	local_user_id: String,
	prediction_buffer: PredictionBuffer = null,
	tick_estimator: ServerTickEstimator = null,
	replication_manager: ReplicationManager = null
) -> void:
	_nakama_client = nakama_client
	_local_user_id = local_user_id
	_prediction_buffer = prediction_buffer if prediction_buffer != null else PredictionBuffer.new()
	_tick_estimator = tick_estimator if tick_estimator != null else ServerTickEstimator.new()
	_replication_manager = replication_manager if replication_manager != null else ReplicationManager.new()

	_nakama_client.match_snapshot_received.connect(_on_snapshot_received)
	_nakama_client.position_corrected.connect(_on_position_corrected)

## Call once per physics tick from the presentation layer. Returns the
## predicted position to actually move the character to this tick.
##
## NOTE: this computes position via simple, collision-UNAWARE
## kinematics (see MovementCalculator) — correct for now since no real
## collision geometry exists yet (that's Phase 10). Once a real map
## exists, `character_controller.gd` should instead drive movement via
## `CharacterBody3D.move_and_slide()` for actual collision resolution,
## and call `record_and_send()` below with the resulting
## collision-resolved position instead of using this method's return
## value directly. Both paths share the same tick/prediction-buffer/
## network bookkeeping (`_record_and_send_internal`), so that
## migration only changes WHERE the position comes from, not how it's
## recorded or sent.
func process_local_tick(input_direction: Vector3, is_grounded: bool, jump_requested: bool, delta: float) -> Vector3:
	current_velocity = MovementCalculator.compute_next_velocity(
		current_velocity, input_direction, is_grounded, jump_requested, delta
	)
	current_position += current_velocity * delta
	_record_and_send_internal(current_position, delta)
	return current_position

## For use once real collision-resolved movement exists (see the
## note on process_local_tick above): records `resolved_position`
## (e.g. a CharacterBody3D's global_position after move_and_slide())
## into the prediction buffer and sends it to the server, without
## this service recomputing its own kinematics.
func record_and_send(resolved_position: Vector3, delta: float) -> void:
	current_position = resolved_position
	_record_and_send_internal(resolved_position, delta)

func _record_and_send_internal(position: Vector3, delta: float) -> void:
	_tick_estimator.advance(delta)
	var tick: int = _tick_estimator.estimate_current_tick()
	_prediction_buffer.record(tick, position, current_velocity * delta)
	_nakama_client.send_player_input(position, delta)

## Returns the interpolated position to render for a remote player,
## delegating to the ReplicationManager fed by snapshot ingestion.
func get_remote_player_position(user_id: String, render_time_seconds: float) -> Vector3:
	return _replication_manager.get_interpolated_position(user_id, render_time_seconds)

func _on_snapshot_received(snapshot: Dictionary) -> void:
	var server_tick: int = snapshot.get("serverTick", 0)
	_tick_estimator.resync(server_tick)
	_replication_manager.ingest_snapshot(snapshot, _local_user_id)

	for player_data in snapshot.get("players", []):
		if player_data.get("userId", "") == _local_user_id:
			var pos: Dictionary = player_data.get("position", {})
			var server_position := Vector3(pos.get("x", 0.0), pos.get("y", 0.0), pos.get("z", 0.0))
			_reconcile_against(server_tick, server_position)
			break

func _reconcile_against(server_tick: int, server_position: Vector3) -> void:
	var entry: PredictionBuffer.Entry = _prediction_buffer.get_entry(server_tick)
	if entry == null:
		# No matching local prediction was recorded at exactly this
		# tick (e.g. right after joining, or a dropped input frame) —
		# skip reconciliation this round rather than guessing. This is
		# a documented limitation, not a silent failure: it means an
		# occasional missed correction opportunity, not incorrect
		# state, since the NEXT snapshot will very likely find a match.
		return

	var result: Reconciler.ReconciliationResult = Reconciler.reconcile(entry.position, server_position)
	if result.needs_correction:
		var entries_after: Array = _prediction_buffer.get_entries_after(server_tick)
		current_position = Reconciler.replay(result.corrected_position, entries_after)

	_prediction_buffer.discard_up_to(server_tick)

func _on_position_corrected(position: Vector3) -> void:
	# An explicit anti-speed-hack correction from the server (distinct
	# from routine reconciliation above, which only runs against
	# snapshots) — apply immediately, no replay, since this means the
	# server rejected our claimed position outright.
	current_position = position
