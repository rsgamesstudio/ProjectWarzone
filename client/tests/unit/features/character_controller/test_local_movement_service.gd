extends GutTest
## Unit tests for
## client/features/character_controller/application/local_movement_service.gd,
## using a fake NakamaClientAdapter so no network/engine dependency is
## needed.

var nakama_fake: MovementTestNakamaClientAdapter
var service: LocalMovementService

const LOCAL_USER_ID := "local-user-1"

func before_each() -> void:
	nakama_fake = MovementTestNakamaClientAdapter.new()
	service = LocalMovementService.new(nakama_fake, LOCAL_USER_ID)

func test_process_local_tick_moves_position_in_input_direction() -> void:
	var result := service.process_local_tick(Vector3(1, 0, 0), true, false, 0.1)
	assert_gt(result.x, 0.0)

func test_process_local_tick_sends_input_to_nakama_client() -> void:
	service.process_local_tick(Vector3(1, 0, 0), true, false, 0.1)
	assert_eq(nakama_fake.sent_inputs.size(), 1)

func test_process_local_tick_records_prediction_and_updates_current_position() -> void:
	var result1 := service.process_local_tick(Vector3(1, 0, 0), true, false, 0.1)
	var result2 := service.process_local_tick(Vector3(1, 0, 0), true, false, 0.1)
	assert_gt(result2.x, result1.x, "position should keep advancing across ticks")
	assert_eq(service.current_position, result2)

func test_snapshot_with_no_matching_prediction_does_not_crash_or_change_position() -> void:
	var before := service.current_position
	nakama_fake.simulate_snapshot({
		"serverTick": 999,
		"elapsedSeconds": 10.0,
		"players": [{"userId": LOCAL_USER_ID, "position": {"x": 50.0, "y": 0.0, "z": 50.0}}],
		"zone": {"center": {"x": 0, "y": 0, "z": 0}, "radiusMeters": 100, "nextShrinkAtSeconds": null},
	})
	assert_eq(service.current_position, before, "no recorded prediction at tick 999 means no reconciliation should happen")

func test_snapshot_matching_a_recorded_tick_with_small_divergence_does_not_correct() -> void:
	# delta=1.0 with the default 10-tick/sec rate lands exactly on
	# tick 10 with no floating-point rounding ambiguity (unlike e.g.
	# 0.1 * 10, which is not guaranteed to land on an exact integer).
	service.process_local_tick(Vector3.ZERO, true, false, 1.0)
	var predicted_before := service.current_position

	nakama_fake.simulate_snapshot({
		"serverTick": 10,
		"elapsedSeconds": 1.0,
		"players": [{"userId": LOCAL_USER_ID, "position": {"x": predicted_before.x, "y": predicted_before.y, "z": predicted_before.z}}],
		"zone": {"center": {"x": 0, "y": 0, "z": 0}, "radiusMeters": 100, "nextShrinkAtSeconds": null},
	})

	assert_eq(service.current_position, predicted_before)

func test_explicit_position_correction_snaps_immediately() -> void:
	service.process_local_tick(Vector3(1, 0, 0), true, false, 0.1)
	nakama_fake.simulate_position_correction(Vector3(-5, 0, -5))
	assert_eq(service.current_position, Vector3(-5, 0, -5))

func test_remote_player_position_delegates_to_replication_manager() -> void:
	nakama_fake.simulate_snapshot({
		"serverTick": 5,
		"elapsedSeconds": 0.5,
		"players": [
			{"userId": LOCAL_USER_ID, "position": {"x": 0.0, "y": 0.0, "z": 0.0}},
			{"userId": "remote-player", "position": {"x": 10.0, "y": 0.0, "z": 10.0}},
		],
		"zone": {"center": {"x": 0, "y": 0, "z": 0}, "radiusMeters": 100, "nextShrinkAtSeconds": null},
	})

	var pos := service.get_remote_player_position("remote-player", 0.5)
	assert_eq(pos, Vector3(10, 0, 10))

func test_local_player_is_not_tracked_as_a_remote_entity() -> void:
	nakama_fake.simulate_snapshot({
		"serverTick": 5,
		"elapsedSeconds": 0.5,
		"players": [{"userId": LOCAL_USER_ID, "position": {"x": 1.0, "y": 0.0, "z": 1.0}}],
		"zone": {"center": {"x": 0, "y": 0, "z": 0}, "radiusMeters": 100, "nextShrinkAtSeconds": null},
	})

	var pos := service.get_remote_player_position(LOCAL_USER_ID, 0.5)
	assert_eq(pos, Vector3.ZERO, "local player should never be tracked via the remote-entity replication path")
