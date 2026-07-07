extends GutTest
## Unit tests for client/features/character_controller/domain/movement_calculator.gd.

func test_accelerates_toward_target_speed_when_input_given() -> void:
	var result := MovementCalculator.compute_next_velocity(
		Vector3.ZERO, Vector3(1, 0, 0), true, false, 0.1
	)
	assert_gt(result.x, 0.0)
	assert_lt(result.x, MovementConfig.MAX_SPEED_METERS_PER_SECOND)

func test_reaches_max_speed_given_enough_time() -> void:
	var velocity := Vector3.ZERO
	for i in range(1000):
		velocity = MovementCalculator.compute_next_velocity(velocity, Vector3(1, 0, 0), true, false, 0.1)
	assert_almost_eq(velocity.x, MovementConfig.MAX_SPEED_METERS_PER_SECOND, 0.01)

func test_decelerates_to_zero_when_no_input() -> void:
	var velocity := Vector3(MovementConfig.MAX_SPEED_METERS_PER_SECOND, 0, 0)
	for i in range(1000):
		velocity = MovementCalculator.compute_next_velocity(velocity, Vector3.ZERO, true, false, 0.1)
	assert_almost_eq(velocity.x, 0.0, 0.01)

func test_never_exceeds_max_speed_even_with_large_delta() -> void:
	var result := MovementCalculator.compute_next_velocity(
		Vector3.ZERO, Vector3(1, 0, 0), true, false, 10.0
	)
	assert_almost_eq(result.length(), MovementConfig.MAX_SPEED_METERS_PER_SECOND, 0.01)

func test_jump_sets_upward_velocity_when_grounded() -> void:
	var result := MovementCalculator.compute_next_velocity(
		Vector3.ZERO, Vector3.ZERO, true, true, 0.016
	)
	assert_eq(result.y, MovementConfig.JUMP_VELOCITY_METERS_PER_SECOND)

func test_jump_request_ignored_when_airborne() -> void:
	var result := MovementCalculator.compute_next_velocity(
		Vector3(0, 2, 0), Vector3.ZERO, false, true, 0.016
	)
	assert_ne(result.y, MovementConfig.JUMP_VELOCITY_METERS_PER_SECOND)

func test_gravity_pulls_down_while_airborne() -> void:
	var result := MovementCalculator.compute_next_velocity(
		Vector3(0, 1.0, 0), Vector3.ZERO, false, false, 0.1
	)
	assert_lt(result.y, 1.0)

func test_grounded_with_no_jump_zeroes_vertical_velocity() -> void:
	var result := MovementCalculator.compute_next_velocity(
		Vector3(0, -5.0, 0), Vector3.ZERO, true, false, 0.016
	)
	assert_eq(result.y, 0.0)

func test_diagonal_input_direction_is_respected() -> void:
	var diagonal := Vector3(1, 0, 1).normalized()
	var result := MovementCalculator.compute_next_velocity(Vector3.ZERO, diagonal, true, false, 0.1)
	assert_gt(result.x, 0.0)
	assert_gt(result.z, 0.0)
	assert_almost_eq(result.x, result.z, 0.001, "symmetric diagonal input should produce symmetric velocity")
