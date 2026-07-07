# Phase 5 — Multiplayer Networking

## Goal

Build the authoritative Nakama match handler and the client-side
prediction/reconciliation/replication pipeline it needs to feel
responsive despite being server-authoritative.

## Decision Made This Phase

**ADR-0006**: match handler language is TypeScript for now (not Go),
with a concrete, documented trigger for revisiting once Phase 14 load
testing exists. Building a Go Nakama plugin requires a matching Go
toolchain and typically a Docker-based builder image — this sandbox
has neither, so shipping one now would mean shipping unverified code,
which this project has avoided at every prior phase.

## What Was Built

### Server (`server/modules/match_handler/`)
- Pure domain logic: `movement_validation.ts` (anti-speed-hack —
  rejects/clamps implausible position claims based on max speed and
  elapsed time) and `safe_zone_schedule.ts` (5-phase deterministic
  shrink, seeded so every client computes an identical zone)
- `handle_player_input.ts` / `build_snapshot.ts` — application-layer
  orchestration, no Nakama API calls, fully unit-testable
- `infrastructure/match_handler.ts` — the actual Nakama `MatchHandler`
  implementation (matchInit through matchSignal), registered as
  `meridian_battle_royale`
- A temporary `create_match_for_testing` RPC for manual QA before
  Phase 11's real matchmaker exists

### Client (`client/networking/{prediction,reconciliation,replication}`, `nakama_client`)
- `NakamaClientAdapter` extended with the realtime socket API:
  `connect_socket_async`, `join_match_async`, `send_player_input`,
  plus signals for incoming snapshots/corrections
- `PredictionBuffer` — records predicted position per tick for later replay
- `Reconciler` — compares predicted vs. authoritative position,
  corrects beyond a 15cm threshold, replays buffered input after
  correction so the present moment snaps back immediately rather than
  visibly rolling back
- `InterpolationBuffer` / `ReplicationManager` — smooths remote
  entities between sparse snapshots (data pipeline only; actual
  character rendering is Phase 6)

## Bugs Caught and Fixed by Actually Checking the Vendored SDK

Three real mistakes were caught by reading the vendored Nakama Godot
SDK source directly rather than assuming API shapes, before they could
ship:
1. `NakamaSocket.connect_async` resolves to a plain **int error code**
   (`OK` on success), not a `NakamaException` — my first draft checked
   `result is NakamaException`, which would never have been true.
2. `NakamaSocket.join_match_async` resolves to a `NakamaAsyncResult`-
   style object exposing `.is_exception()`/`.get_exception()` — a
   *different* pattern from (1), and also different from my first
   draft's `result is NakamaException` check.
3. The safe-zone radius originally jumped straight to each phase's
   target radius instead of interpolating the shrink over that phase's
   duration — caught while writing the "radius strictly decreases
   over time" test, fixed before it shipped.

## Verification Performed

- **Server:** `tsc --noEmit` clean, 27/27 tests passing (17 domain, 8
  application, 2 wiring smoke tests using a fake Nakama initializer),
  esbuild bundle verified to attach `InitModule` correctly — same
  rigor as Phase 4.
- **Client:** GDScript reviewed line-by-line against the vendored
  SDK's actual method signatures (not assumed from memory — this is
  what caught bugs 1 and 2 above). Still not executable in this
  sandbox; verify in a real Godot 4.3+ editor. 26 new unit tests exist
  for everything that doesn't require the SDK/engine (prediction,
  reconciliation, replication math) and pass by structural/logical
  review, but haven't been run by an actual GUT process here.

## Explicitly Out of Scope This Phase

- Actual character rendering/movement (Phase 6 consumes
  `PredictionBuffer`/`Reconciler`/`ReplicationManager`, doesn't yet exist)
- Weapons, damage, loot (Phase 7/10)
- Real matchmaking (Phase 11) — `create_match_for_testing` is an
  explicitly temporary stand-in
- Delta-compressed snapshots (full snapshot every tick today — a
  known, documented Phase 13 optimization opportunity)
- Reliable reconnect handling beyond marking a player `connected:
  false` on leave (the full reconnect flow needs a resuming client,
  which doesn't exist until Phase 6)

## Testing Checklist

**Server (verifiable by running the commands below):**
- [ ] `cd server/modules/match_handler && npm install && npm run typecheck` — passes
- [ ] `npm test` — 27/27 pass
- [ ] `npm run build` — produces `build/index.js`
- [ ] Full stack up, call `create_match_for_testing` RPC → get back a match ID
- [ ] Join that match with two separate test sessions, send `PlayerInput` messages, confirm both receive `Snapshot` broadcasts with both players' positions
- [ ] Send an input claiming an impossible jump (e.g. 500m in one tick) → confirm a `PositionCorrection` message arrives and the player's broadcast position does NOT reflect the impossible claim

**Client (requires a real Godot 4.3+ editor):**
- [ ] `./tools/build-scripts/run_gdscript_tests.sh` — all tests pass, including the 26 new ones
- [ ] Manually exercise `NakamaClientAdapter.connect_socket_async()` / `join_match_async()` against the local Docker stack and confirm no runtime errors (this is the one thing that could NOT be checked in this sandbox — verify before relying on it)

## Next Milestone

**Phase 6 — Character Controller**: third-person movement, camera rig,
animation state machine, wiring `PredictionBuffer` for local movement
and `ReplicationManager` for remote players into an actual scene.

## Estimated Completion

**~12%** of overall project (Phase 5 of 16 complete).
