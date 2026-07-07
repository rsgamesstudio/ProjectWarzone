# Phase 7 — Weapons

## Goal

Weapon classes, hit registration, and attachments groundwork. Also
covers a side addition made at explicit request: a lobby theme music
system.

## Key Architectural Decision: ADR-0007

Nakama has no physics engine and no replicated level geometry
server-side — full server-side raycasting (what a client does
locally) isn't possible without building a parallel physics
representation on the server, well beyond this phase's scope. Decision:
**client-reported hits with server-side plausibility validation** —
the server checks a claimed hit against data it already has (known
positions from the snapshot system, weapon range, fire-rate cooldown)
and rejects claims that are geometrically implausible, without
literally re-simulating the shot. This is a deliberate, bounded-trust
decision, documented so it's never mistaken for full lag-compensated
hit detection.

Also in ADR-0007: **all weapon names are original and fictional** — no
real firearm manufacturer names/model numbers, since those carry
actual trademark/licensing risk (several manufacturers have pursued
claims against game studios over this specifically).

## What Was Built

### Server (`server/modules/match_handler/`)
- `weapon_definitions.ts` — 5 original weapon classes (VK-12 assault
  rifle, Wisp SMG, Longbow sniper, Reaper-12 shotgun, Talon Pistol)
  with damage/range/fire-rate/magazine/reload stats
- `damage_calculator.ts` — linear damage falloff by distance
- `hit_validation.ts` — the plausibility check described above
- `handle_weapon_fire.ts` — orchestrates validation + damage
  application + elimination detection
- `match_handler.ts` extended: players now track health/elimination/
  per-weapon fire cooldowns; new `WeaponFireClaim` opcode handling
  broadcasts `DamageEvent`/`EliminationEvent` to all clients

### Client (`client/features/weapons/`)
- `weapon_definitions.gd` / `damage_calculator.gd` — mirrors of the
  server data, for local UX prediction only (server always wins)
- `weapon_controller.gd` — ammo/fire-rate-cooldown/reload state
  machine, fully tested
- `NakamaClientAdapter` extended with `send_weapon_fire_claim()` and
  `damage_event_received`/`elimination_event_received` signals

**Not built yet** (explicitly, not an oversight): the actual
presentation-layer weapon — a scene attached to the character
controller, muzzle flash, the local raycast that measures
`distance_meters`, ammo/hit-marker UI. `WeaponController`/
`WeaponDefinitions` are ready for that scene; building it wasn't
rushed into this same pass so it could get the same test rigor as
everything else, consistent with "one production-ready module at a
time."

### Side addition: Lobby music (`client/core/audio/`)
Built at explicit request. `MusicPlayer` (registered via `Bootstrap`,
must be an actual scene-tree Node to play audio) with
`play_looped()`/`pause_for_match()`/`resume_if_paused()`. Wired: login
screen starts the theme looped; lobby screen resumes it (a no-op today
since nothing pauses it yet — that's Phase 11's job once a real
match-join flow exists to call `pause_for_match()`).

The uploaded track ("Iron Echo March") is AI-generated via Suno;
commercial usage rights depend on subscription tier — flagged in
`client/assets/README.md`'s provenance log as license-TBD rather than
assumed either way.

## Verification Performed

- **Server:** `tsc --noEmit` clean, 52/52 tests passing (35 domain, 15
  application, 2 wiring smoke tests), esbuild bundle verified to load
  and attach `InitModule` correctly.
- **Client:** 25 new unit tests for the weapons domain/application
  layers (all passing by structural/logical review — this sandbox
  still has no Godot binary to execute them). Two real test bugs were
  caught and fixed during writing: `start_reload()`'s "already full"
  no-op guard silently prevented two tests from actually entering the
  reloading state they meant to test — both fixed by firing at least
  one round first. `MusicPlayer` is presentation-layer/audio-server
  dependent and isn't unit tested, same category as other
  scene-tree-bound code this project has been consistent about
  flagging rather than claiming false coverage for.

## Explicitly Out of Scope This Phase

- Actual weapon presentation (see Notes above)
- Attachments (scopes, grips, magazines) — planned but not built this pass
- Throwables — separate content, not scoped to this phase
- Kill feed UI (Phase 9) — the server events exist; nothing renders them yet

## Testing Checklist

**Server (verifiable by running the commands below):**
- [ ] `cd server/modules/match_handler && npm install && npm run typecheck && npm test` — 52/52 pass
- [ ] `npm run build` — produces `build/index.js`
- [ ] Full stack: fire a weapon claim within plausible range/rate → `DamageEvent` broadcasts with correct falloff-adjusted damage
- [ ] Fire a claim from an implausible distance or faster than fire rate → claim is silently dropped, no damage applied
- [ ] Reduce a target to 0 health → `EliminationEvent` broadcasts, further claims against them are rejected

**Client (requires a real Godot 4.3+ editor):**
- [ ] `./tools/build-scripts/run_gdscript_tests.sh` — all tests pass, including the 25 new weapons cases
- [ ] Login screen: lobby theme plays and loops correctly
- [ ] Lobby screen: music continues uninterrupted from login (resume_if_paused is a no-op here, as expected)

## Next Milestone

**Phase 8 — Inventory**: client + server inventory sync.

## Estimated Completion

**~18%** of overall project (Phase 7 of 16 complete, plus the lobby
music addition).
