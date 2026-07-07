# Phase 6 — Character Controller

## Goal

Build third-person movement and camera, wiring Phase 5's prediction/
reconciliation/replication pipeline into an actual character. Also
covers two additions made at explicit request during this phase: a
login screen (first real UI wiring of Phase 4's `AuthService`) and an
expanded lobby UI matching a second round of reference images.

## What Was Built

### Character movement (`client/features/character_controller/`)
- `MovementCalculator` — pure velocity calculation (acceleration/
  deceleration toward max speed, jump, gravity), no `CharacterBody3D`
  dependency, fully unit-tested
- `ServerTickEstimator` — estimates the current server tick locally
  between snapshots, resyncing whenever a real snapshot arrives
- `LocalMovementService` — orchestrates prediction, network send, and
  reconciliation; exposes both a collision-unaware kinematic path
  (`process_local_tick`, used today) and a collision-aware path
  (`record_and_send`, for once real level geometry exists in Phase 10)
- `character_controller.gd`/`.tscn` — the actual local-player scene.
  Uses a placeholder `CapsuleMesh` — no rigged character art exists
  yet (that's the Blender pipeline's job, not something generated
  here)
- `remote_player.gd`/`.tscn` — visual-only remote player representation

### Login screen (`client/features/authentication/presentation/`)
First real UI wiring of `AuthService`, built at explicit request
alongside a reference image. Guest and Email ("Sign in with RS GAMES
STUDIO") are fully functional; Google is functional on HTML5/Web only
(existing scope limit from Phase 4); Facebook was in the reference
image but isn't part of this project's original auth scope, so it's
shown but wired to a "not implemented" message rather than faked.
Inserted into `UIRoot`'s flow: splash → loading → **login** → lobby.

### Lobby expansion (`client/features/lobby/`)
Expanded to match a second reference image's structure: VIP tier
badge, promo bundle banner, Season Path progress, a Founders Cup event
banner, world chat line. All content uses original names — see
**ADR-0005's Phase 6 addendum**.

## IP Note (second round)

The second reference image round surfaced different issues than the
first: not trademarked map names this time, but **branded mechanic
names from a specific existing title** (Free Fire's "Luck Royale") and
Activision's product name appearing inside actual game content rather
than just our project's external codename ("Warzone Championship"/
"Warzone Royale"). Replaced with **"Fortune Cache"**, **"Nightfall
Bundle"**, **"Founders Cup"**, and **"Season Path"** (the last also
sidesteps "Battle Pass"'s trademark history, independent of any single
reference image). Full reasoning in ADR-0005's addendum. A regression
test (`test_mock_lobby_data_provider.gd`) now guards against all of
these names, plus the first round's, re-entering the mock data.

## Verification Performed

Same pattern as every prior phase: domain/application-layer GDScript
(the parts with no scene-tree/engine dependency) has real unit tests —
23 new cases across `MovementCalculator`, `ServerTickEstimator`, and
`LocalMovementService` (the latter using a fake `NakamaClientAdapter`,
consistent with the fixture pattern established in Phase 4).
Presentation-layer code (`character_controller.gd`, `login_screen.gd`,
`lobby_screen.gd`) was reviewed structurally — balanced brackets/
indentation, and every `%UniqueName` reference cross-checked against
its scene's actual node names — but **not executed**; this sandbox
still has no Godot binary. Verify in a real Godot 4.3+ editor before
relying on any of it.

## Explicitly Out of Scope This Phase

- Animation state machine (no rigged character art exists to animate)
- Actual spawning/despawning of `character_controller`/`remote_player`
  on match join/leave (needs Phase 10's map + Phase 11's matchmaking)
- Collision-aware movement (`record_and_send` exists but isn't the
  active path yet — no level geometry to collide with until Phase 10)
- Gamepad input, remapping UI

## Testing Checklist

**Domain/application (verifiable by running GUT):**
- [ ] `./tools/build-scripts/run_gdscript_tests.sh` — all tests pass, including the 23 new character_controller cases

**Presentation (requires a real Godot 4.3+ editor):**
- [ ] Open the project; no script errors
- [ ] Run the splash → loading → login → lobby flow; "Continue as
      Guest" successfully authenticates against the local Docker stack
- [ ] Manually instantiate `character_controller.tscn`, call
      `setup(some_user_id)`, confirm WASD + mouse-look + Space move the
      capsule and rotate the camera
- [ ] Confirm the lobby renders VIP tier, Season Path progress bar,
      Founders Cup banner, and world chat line correctly from the mock data

## Next Milestone

**Phase 7 — Weapons**: weapon classes, hit registration, attachments.

## Estimated Completion

**~15%** of overall project (Phase 6 of 16 complete, plus the login
screen and lobby expansion additions).
