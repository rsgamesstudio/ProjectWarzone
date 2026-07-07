# Phase 4 — Authentication

## Goal

Implement Guest/Google/Email login end-to-end: Firebase handles
identity, Nakama issues sessions, and our own `warzone_accounts`/
`warzone_nicknames` tables (ADR-0002) get provisioned automatically on
login, with a dedicated RPC for claiming a permanent nickname.

## Architectural Corrections Made This Phase

Two real bugs were caught by actually implementing this phase, and
fixed via ADR rather than silently patched:

1. **ADR-0003 — Single database topology.** Phase 2 put custom game
   tables in a separate `warzone` Postgres database from Nakama's own
   `nakama` database. This turned out to be unworkable: Nakama runtime
   modules can only reach the single database they were started with,
   and Postgres has no cross-database query path. Consolidated to one
   database; `warzone_*` table naming keeps the two schemas visually
   distinct within it.
2. **Migration 0002 — one nickname per account.** Designing the claim
   transaction surfaced a missing invariant: nothing stopped two
   concurrent provisioning calls for a brand-new account from each
   inserting a placeholder nickname row. Added
   `UNIQUE(account_id)` to `warzone_nicknames`.

## What Was Built

### Server (`server/modules/authentication/`)
- Real Nakama TypeScript runtime module, using Nakama's own
  `authenticateDevice`/`authenticateEmail`/`authenticateCustom` rather
  than custom login RPCs (ADR-0004)
- `registerAfterAuthenticate*` hooks provision `warzone_accounts` +
  a placeholder nickname idempotently on every login
- `registerBeforeAuthenticateCustom` verifies a Firebase ID token
  (via Google's `tokeninfo` HTTP endpoint — see
  `firebase_token_verifier.ts` for the documented tradeoff vs. local
  RS256 verification) and rewrites `custom_id` to the verified
  Firebase UID before Nakama accepts it
- RPC `claim_nickname` — validated, atomic, race-safe against the
  database's unique index
- Vendored the real ambient Nakama runtime types
  (`types/nakama-runtime.d.ts`, from `heroiclabs/nakama-common`) after
  discovering the initial approach (an npm import) doesn't match how
  Nakama TS modules actually consume these types

### Client (`client/networking/nakama_client/`, `client/features/authentication/`)
- Vendored the real Nakama Godot client SDK (v3.3.1-godot4)
- `NakamaClientAdapter` — HTTP/session API wrapper (full realtime
  socket API deferred to Phase 5)
- `GuestIdentityProvider` — stable device ID, generated via `Crypto`
  and persisted to `user://`, works on every platform today
- `FirebaseWebIdentityProvider` — Google/Email login via the Firebase
  Web SDK, bridged through `JavaScriptBridge`. **HTML5/Web exports
  only** — native Android/iOS Google/Email login needs a genuine
  native Godot plugin, explicitly tracked as follow-up work rather
  than silently assumed done (ADR-0004, feature README)
- `AuthService` — orchestrates all three login flows + nickname claiming

## Verification Performed

Unlike the GDScript-only phases, this phase's server-side TypeScript
was **actually compiled and executed**, not just reviewed:
- `npx tsc --noEmit` — clean against the real vendored Nakama runtime types
- `node --test` via `tsx` — 13 tests passing (9 domain, 4 application, using an in-memory fake of `nk.sqlQuery`/`sqlExec`)
- `npm run build` (esbuild) — bundle produced; loaded via plain `node -e` to confirm it actually attaches a global `InitModule`, exactly as Nakama's loader expects

The client-side GDScript was reviewed for structural correctness
(balanced brackets/indentation, correct `nkruntime`-equivalent
API usage against the vendored SDK's actual method signatures) but
**could not be executed** — this sandbox has no Godot binary and no
network path to Godot's release CDN. Verify against a real Godot 4.3+
editor before relying on it; see the testing checklist below.

## Addendum: Early UI Prototype (Splash / Loading / Lobby)

Built at explicit request, ahead of its scheduled phases (UI System
is Phase 9; Matchmaking, which the lobby's real data depends on, is
Phase 11). Reference images supplied for layout inspiration contained
real Call of Duty trademarks/copyrighted character art (Verdansk,
Rebirth Island, Rust, Plunder, Blood Money, the "Ghost" mask) and a
logo treatment that closely copied Call of Duty: Warzone's trade
dress — none of that was used. See **ADR-0005** for the original
naming/content decisions made instead (map "Meridian", modes "Battle
Royale"/"Skirmish", currencies "Credits"/"Marks").

Built:
- `client/features/ui/presentation/ui_root.*` — the actual
  `run/main_scene`, sequencing splash → loading → lobby
- `client/features/ui/presentation/splash_screen/` — studio logo
  intro using the real RS GAMES crest
- `client/features/ui/presentation/loading_screen/` — progress bar
  (simulated — no real asset streaming exists yet) + rotating,
  original tip text
- `client/features/lobby/presentation/` — lobby screen + mode cards,
  rendering a `MockLobbyDataProvider` (explicitly temporary, documented
  replacement plan tied to Phases 8/9/11)

This is a UI/UX prototype with mock data, not a wired feature — Start/
Loadout/Clan/Leaderboard/Store buttons log which future phase
implements them rather than faking success.

## Testing Checklist

**Server (can be verified by running the commands below):**
- [ ] `cd server/modules/authentication && npm install && npm run typecheck` — passes
- [ ] `npm test` — 13/13 tests pass
- [ ] `npm run build` — produces `build/index.js`
- [ ] Full stack: `docker compose up -d` (infra/docker), then confirm the Nakama container logs show `Project Warzone authentication module initialized.`
- [ ] Guest login via Nakama console or a test client → confirm a `warzone_accounts` row + placeholder `warzone_nicknames` row appear
- [ ] Call `claim_nickname` RPC with a valid name → success; call again with the same name from a different account → `ALREADY_TAKEN`

**Client (requires a real Godot 4.3+ editor — not verified in this sandbox):**
- [ ] Open the project; no script errors on load
- [ ] Run scene → splash screen shows the RS GAMES crest, fades, transitions to loading screen
- [ ] Loading screen fills its progress bar over ~2.5s, tips rotate, transitions to lobby
- [ ] Lobby renders mock player/currency/mode data; clicking Start/Loadout/etc. prints a "not implemented yet" message to the console rather than doing nothing or erroring
- [ ] `./tools/build-scripts/run_gdscript_tests.sh` — all unit tests pass, including the new authentication/ui/lobby suites

## Next Milestone

**Phase 5 — Multiplayer Networking**: extend `NakamaClientAdapter`
with the realtime socket API, build the match handler's client-side
prediction/reconciliation core.

## Estimated Completion

**~9%** of overall project (Phase 4 of 16 complete, plus an early,
explicitly-scoped UI prototype).
