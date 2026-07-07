class_name MovementTestNakamaClientAdapter
extends NakamaClientAdapter
## Test double for NakamaClientAdapter, scoped to
## character_controller's tests. Overrides `_init` without calling
## `super()` to skip the real constructor's `Nakama.create_client(...)`
## call, same rationale as
## `tests/unit/features/authentication/fixtures/fake_nakama_client_adapter.gd`
## (kept as a separate class here, rather than reused, since GDScript
## class_name identifiers must be globally unique and each feature's
## fixtures are scoped to that feature's tests by convention).

var sent_inputs: Array = [] # Array of {position: Vector3, delta_seconds: float}

func _init() -> void:
	pass

func send_player_input(position: Vector3, delta_seconds: float) -> void:
	sent_inputs.append({"position": position, "delta_seconds": delta_seconds})

## Test helper: simulates the server broadcasting a snapshot.
func simulate_snapshot(snapshot: Dictionary) -> void:
	match_snapshot_received.emit(snapshot)

## Test helper: simulates an explicit anti-speed-hack correction.
func simulate_position_correction(position: Vector3) -> void:
	position_corrected.emit(position)
