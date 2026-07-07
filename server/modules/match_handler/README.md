# Match Handler Module

**Layer:** Nakama server module
**Status:** Implemented (Phase 5 movement/zone + Phase 7 weapons/damage).
Loot/attachments content is a later phase; this module's job is the
authoritative simulation loop, not gameplay content beyond damage.

## Responsibility

The authoritative real-time match simulation: player position
tracking (server-validated, never trusting the client outright), the
safe-zone shrink schedule, weapon hit validation and damage
application (see ADR-0007 for the hit-registration model), and
broadcasting per-tick snapshots plus damage/elimination events. See
ADR-0006 for why this is TypeScript rather than Go, at least for now.

## Structure

- `domain/movement_validation.ts` — pure anti-speed-hack math (no I/O)
- `domain/safe_zone_schedule.ts` — pure, deterministic zone shrink math (5 phases, seeded RNG for reproducible center shifts)
- `domain/match_state.ts` — state type definitions (now including health/elimination/fire-cooldown tracking), tick rate constant
- `domain/match_opcodes.ts` — wire-protocol opcodes (manually kept in sync with the client — see that file's docstring)
- `domain/weapon_definitions.ts` — original, fictional weapon stats table (ADR-0007)
- `domain/damage_calculator.ts` — pure damage falloff math
- `domain/hit_validation.ts` — server-side hit *plausibility* validation (ADR-0007 — not full re-simulation)
- `application/handle_player_input.ts` — validates + applies one player's input message
- `application/build_snapshot.ts` — builds the per-tick broadcast payload
- `application/handle_weapon_fire.ts` — validates + applies one weapon fire claim
- `infrastructure/match_handler.ts` — implements Nakama's `MatchHandler` interface, wiring the above together
- `index.ts` — registers the match under the name `meridian_battle_royale`, plus a temporary `create_match_for_testing` RPC

## Depends On

- Nakama's built-in match handler runtime (no external DB access needed by this module — all state is in-memory per match, per ARCHITECTURE.md §7)

## Public Interface

- Match name: `meridian_battle_royale` (registered via `initializer.registerMatch`)
- RPC `create_match_for_testing` — **TEMPORARY**, manual QA only; real match creation is Phase 11's matchmaker
- Wire protocol (client <-> server), opcodes in `domain/match_opcodes.ts`:
  - `PlayerInput` (1): client -> server, `{position: {x,y,z}, deltaSeconds: number}`
  - `Snapshot` (2): server -> all clients, `{serverTick, elapsedSeconds, players: [...], zone: {...}}`
  - `PositionCorrection` (3): server -> single client, corrected `{x,y,z}` when their claimed position was rejected
  - `WeaponFireClaim` (4): client -> server, `{targetId, weaponClass, claimedDistanceMeters}`
  - `DamageEvent` (5): server -> all clients, `{targetId, sourceId, amount, remainingHealth}`
  - `EliminationEvent` (6): server -> all clients, `{userId}`

## Tests

- `npm test`: 52 tests — 35 domain (8 movement validation, 9 safe zone
  schedule, 4 weapon definitions, 7 damage calculator, 7 hit
  validation), 15 application (4 input handling, 4 snapshot building,
  7 weapon fire handling), 2 wiring smoke tests verifying `InitModule`
  actually registers the match + RPC with a fake initializer
- `npm run typecheck` — clean against the vendored Nakama runtime types
- `npm run build` — bundle verified to attach a global `InitModule` correctly

## Notes

Tick rate is a conservative 10Hz (see `domain/match_state.ts`) — see
ADR-0006 for why this isn't pushed higher without real load-test data
first. The snapshot broadcast is unconditional every tick (no delta
compression yet) — a known, documented optimization opportunity for
Phase 13, not an oversight. Hit registration trusts the client's
raycast claim within a bounded plausibility check (ADR-0007) rather
than fully re-simulating the shot server-side — Nakama has no physics
engine to do so against, and there's no level geometry to check
against yet regardless (Meridian is Phase 10).
