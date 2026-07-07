# Weapons

**Layer:** Client feature module
**Status:** Partially implemented (Phase 7) — domain/application logic
complete and tested; presentation (an actual weapon-holding scene
attached to the character controller, muzzle flash, raycast wiring)
is not yet built. Server-side counterpart is fully implemented in
`server/modules/match_handler`.

## Responsibility

Weapon classes, ammo/reload/fire-rate state, and client-side damage
prediction for immediate UX feedback. Authoritative damage lives
server-side — see ADR-0007 for the full hit-registration model
(client-reported hits, server-side plausibility validation, not full
server-side raycasting, since Nakama has no physics engine).

## Structure

- `domain/weapon_definitions.gd` — mirrors the server's weapon stats table (5 original, fictional weapon classes — see ADR-0007)
- `domain/damage_calculator.gd` — mirrors the server's falloff math, for UI prediction only
- `application/weapon_controller.gd` — ammo/fire-rate-cooldown/reload state machine

## Depends On

- `client/networking/nakama_client` (`send_weapon_fire_claim`, `damage_event_received`, `elimination_event_received`)

## Public Interface

- `WeaponDefinitions.get_definition(weapon_id) -> WeaponDefinition`
- `WeaponController.try_fire() -> bool`
- `WeaponController.start_reload()`
- `WeaponController.tick(delta)`
- `DamageCalculator.calculate_damage(weapon, distance_meters) -> float`

## Tests

- `client/tests/unit/features/weapons/test_weapon_definitions.gd` (5 cases, including a real-firearm-name regression guard)
- `client/tests/unit/features/weapons/test_damage_calculator.gd` (4 cases, including a cross-check against the server's known-good calculation at one point)
- `client/tests/unit/features/weapons/test_weapon_controller.gd` (16 cases covering the full ammo/cooldown/reload state machine)

## Notes

**Not yet built**: the actual presentation-layer weapon (a scene
attached to `character_controller`, muzzle flash/tracer visuals, the
local raycast that measures `distance_meters` for
`send_weapon_fire_claim`, and UI hooks for ammo count / hit markers /
damage indicators). `WeaponController` and `WeaponDefinitions` are
ready for that scene to be built on top of — deliberately not rushed
out alongside the domain layer in the same pass, consistent with this
project's "one production-ready module at a time" rule; this phase
delivered the parts that could be fully tested, not a half-verified
presentation layer on top.

See `server/modules/match_handler/README.md` for the authoritative
server-side counterpart (hit validation, damage application,
elimination, kill-feed events).
