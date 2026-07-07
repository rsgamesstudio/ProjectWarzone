# Character Controller

**Layer:** Client feature module
**Status:** Implemented (Phase 6) — movement, camera, and networking
wiring. Animation state machine and remote-player spawning/despawning
logic remain open (see Notes).

## Responsibility

Third-person movement, camera rig, client-side prediction of local
player movement reconciled against server snapshots.

## Structure

- `domain/movement_config.gd` — tuning constants (speed, acceleration, jump, gravity), single source of truth
- `domain/movement_calculator.gd` — pure velocity calculation, no `CharacterBody3D` dependency, fully unit-tested
- `domain/server_tick_estimator.gd` — estimates the current server tick locally between snapshots
- `application/local_movement_service.gd` — orchestrates prediction, network send, and reconciliation
- `presentation/character_controller.gd` / `.tscn` — the actual local-player scene (placeholder capsule mesh — see Notes)
- `presentation/remote_player.gd` / `.tscn` — visual-only remote player representation, driven externally

## Depends On

- `client/networking/prediction`, `client/networking/reconciliation`, `client/networking/replication`
- `client/networking/nakama_client` (via `Services.resolve("NakamaClient")`)
- `client/core/di`

## Public Interface

- `CharacterController.setup(local_user_id: String)` — must be called before use (see Notes on spawning)
- `LocalMovementService.process_local_tick(...) -> Vector3` — collision-unaware kinematic path (current default; see next)
- `LocalMovementService.record_and_send(resolved_position, delta)` — collision-aware path for once real level geometry exists
- `RemotePlayer.update_position(interpolated_position: Vector3)`

## Tests

- `client/tests/unit/features/character_controller/test_movement_calculator.gd` (9 cases)
- `client/tests/unit/features/character_controller/test_server_tick_estimator.gd` (6 cases)
- `client/tests/unit/features/character_controller/test_local_movement_service.gd` (8 cases, using a fake `NakamaClientAdapter`)
- `character_controller.gd`/`remote_player.gd` themselves are not unit tested (presentation-layer, scene-tree/input dependent) — reviewed structurally, not executed; see PHASE_06 report

## Notes

**No rigged character art exists yet** — `character_controller.tscn`
and `remote_player.tscn` use a plain `CapsuleMesh` placeholder. Real
character models/animations come from the Blender asset pipeline
(`tools/asset-pipeline/`), not something generated here; swapping the
placeholder for real art + an animation state machine is explicitly
left open, not scheduled to a specific phase yet.

**Collision-aware movement migration**: `process_local_tick()` uses
simple, collision-unaware kinematics because no real level geometry
exists yet (Meridian itself is Phase 10). Once it does,
`character_controller.gd` should drive movement via
`CharacterBody3D.move_and_slide()` (already partially wired — see that
script) and call `record_and_send()` with the collision-resolved
position instead. Both paths share the same prediction-buffer/network
bookkeeping, so this is a small, contained change when the time comes.

**Spawning**: nothing currently spawns `character_controller.tscn` or
`remote_player.tscn` as part of a real match-join flow — that depends
on Phase 10 (map) and Phase 11 (matchmaking) both existing. `setup()`
must be called manually for standalone testing in the meantime.

Input map (`move_forward`/`move_back`/`move_left`/`move_right`/`jump`)
is defined in `client/project.godot` — keyboard-only for now; gamepad
bindings and a real remapping UI are future work.
