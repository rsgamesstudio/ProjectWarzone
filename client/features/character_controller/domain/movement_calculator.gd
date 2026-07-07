class_name MovementCalculator
extends RefCounted
## Pure velocity calculation for character movement — deliberately NOT
## using `CharacterBody3D`/`move_and_slide()` directly, so this can be
## unit-tested with GUT without a running physics server. The
## presentation-layer `character_controller.gd` calls this every
## physics tick and applies the result via `move_and_slide()` itself.
##
## This is the SAME function used for local prediction each tick — it
## does not talk to the network at all; `local_movement_service.gd`
## is what feeds its output into `PredictionBuffer` and sends it to
## the server.

## @param current_velocity Velocity at the start of this tick.
## @param input_direction Camera-relative, already-normalized desired
##   movement direction on the XZ plane (Vector3 with y=0). Zero
##   vector means "no input" (decelerate to a stop).
## @param is_grounded Whether the character is currently on the ground
##   (as reported by CharacterBody3D.is_on_floor() at the call site).
## @param jump_requested Whether a jump input was buffered this tick.
##   Only takes effect if `is_grounded` is also true.
## @param delta Seconds elapsed this tick.
static func compute_next_velocity(
	current_velocity: Vector3,
	input_direction: Vector3,
	is_grounded: bool,
	jump_requested: bool,
	delta: float
) -> Vector3:
	var horizontal_velocity := Vector3(current_velocity.x, 0.0, current_velocity.z)
	var target_horizontal := input_direction * MovementConfig.MAX_SPEED_METERS_PER_SECOND

	var has_input: bool = input_direction.length_squared() > 0.0001
	var acceleration: float = (
		MovementConfig.ACCELERATION_METERS_PER_SECOND_SQUARED if has_input
		else MovementConfig.DECELERATION_METERS_PER_SECOND_SQUARED
	)
	horizontal_velocity = horizontal_velocity.move_toward(target_horizontal, acceleration * delta)

	var vertical_velocity: float = current_velocity.y
	if is_grounded:
		vertical_velocity = MovementConfig.JUMP_VELOCITY_METERS_PER_SECOND if jump_requested else 0.0
	else:
		vertical_velocity -= MovementConfig.GRAVITY_METERS_PER_SECOND_SQUARED * delta

	return Vector3(horizontal_velocity.x, vertical_velocity, horizontal_velocity.z)
