extends CharacterBody3D
## Third-person character controller for the LOCAL player. Uses real
## `CharacterBody3D.move_and_slide()` for collision-aware movement
## (Godot resolves collisions against whatever level geometry exists —
## none yet, since Meridian itself is Phase 10), and delegates
## networking/prediction bookkeeping to `LocalMovementService` via
## `record_and_send()` — see that method's docstring for why this is
## the forward-looking path rather than `process_local_tick()`'s
## simplified kinematics.
##
## SCOPE NOTE: this scene is not yet spawned by any real match-join
## flow (that requires Phase 10's map and Phase 11's matchmaking to
## exist). Call `setup()` manually to use it standalone during
## development/testing in the meantime.

@onready var spring_arm: SpringArm3D = %SpringArm
@onready var camera: Camera3D = %Camera

const MOUSE_SENSITIVITY: float = 0.003
const MIN_PITCH_DEGREES: float = -80.0
const MAX_PITCH_DEGREES: float = 80.0

var _movement_service: LocalMovementService = null
var _local_user_id: String = ""
var _camera_yaw: float = 0.0
var _camera_pitch: float = 0.0

## Must be called before this controller is usable — normally by
## whatever spawns it on match join (Phase 10/11). `local_user_id`
## should come from the current AuthService session
## (client/features/authentication/application/auth_service.gd).
func setup(local_user_id: String) -> void:
	_local_user_id = local_user_id
	var nakama_client: NakamaClientAdapter = Services.resolve("NakamaClient")
	_movement_service = LocalMovementService.new(nakama_client, _local_user_id)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_camera_yaw -= event.relative.x * MOUSE_SENSITIVITY
		_camera_pitch = clamp(
			_camera_pitch - event.relative.y * MOUSE_SENSITIVITY,
			deg_to_rad(MIN_PITCH_DEGREES),
			deg_to_rad(MAX_PITCH_DEGREES)
		)
		rotation.y = _camera_yaw
		spring_arm.rotation.x = _camera_pitch

func _physics_process(delta: float) -> void:
	if _movement_service == null:
		return # setup() hasn't been called yet — nothing to do.

	var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var camera_basis: Basis = global_transform.basis
	var direction := (camera_basis.x * input_2d.x) + (camera_basis.z * input_2d.y)
	direction.y = 0.0
	if direction.length() > 0.001:
		direction = direction.normalized()

	var jump_requested := Input.is_action_just_pressed("jump")

	velocity = MovementCalculator.compute_next_velocity(velocity, direction, is_on_floor(), jump_requested, delta)
	move_and_slide()

	_movement_service.record_and_send(global_position, delta)

## Called each frame (not physics frame) by whatever owns the remote
## player pool (Phase 10/11) to update a remote player's rendered
## position from ReplicationManager's interpolation. Lives here as a
## static helper rather than on LocalMovementService directly, since
## it's the character_controller feature's job to know how a "remote
## player" gets rendered, not the networking layer's.
static func get_remote_render_position(
	movement_service: LocalMovementService, user_id: String, render_time_seconds: float
) -> Vector3:
	return movement_service.get_remote_player_position(user_id, render_time_seconds)
