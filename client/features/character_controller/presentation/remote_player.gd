extends Node3D
## Visual-only representation of a REMOTE player, driven by whatever
## owns the match session's `ReplicationManager` (Phase 10/11 — no
## real match-session owner exists yet, same scope note as
## `character_controller.gd`). This node does not talk to the network
## itself; it's purely "given a position, render it there."
##
## No collision shape yet — a hitbox for weapon hit-detection is
## Phase 7's concern, not this one.

var user_id: String = ""

func set_user_id(id: String) -> void:
	user_id = id

## Called every frame by the owning match-session controller with the
## interpolated position from `ReplicationManager.get_interpolated_position()`.
func update_position(interpolated_position: Vector3) -> void:
	global_position = interpolated_position
