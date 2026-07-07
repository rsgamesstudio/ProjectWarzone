# Project Warzone — System Architecture

## 1. Purpose of this document

This is the authoritative reference for how Project Warzone is
structured, why each major decision was made, and what rules every
contributor (human or AI-assisted) must follow when adding code. It
will be updated every phase; changes to it require an ADR
(`docs/adr/`) rather than a silent edit.

## 2. High-Level Topology

```
                ┌────────────────────┐
                │   Godot 4 Client    │  (Android / PC)
                │  GDScript + C#      │
                └─────────┬───────────┘
                          │ WebSocket / gRPC (TLS)
                          ▼
                ┌────────────────────┐
                │   Nakama Cluster    │  Authoritative match simulation,
                │ (Go runtime + TS/Go │  matchmaking, session mgmt,
                │  custom modules)    │  RPC validation, anti-cheat hooks
                └───┬───────────┬────┘
                    │           │
          ┌─────────▼──┐   ┌────▼─────────┐
          │ PostgreSQL │   │    Redis      │
          │ (durable   │   │ (matchmaking  │
          │ player &   │   │ queue, session│
          │ match data)│   │ cache, presence)│
          └────────────┘   └───────────────┘

        ┌───────────────────────────────────────┐
        │ Firebase: Auth, Cloud Messaging,       │
        │ Analytics (client-facing identity &    │
        │ engagement layer, NOT gameplay truth)  │
        └───────────────────────────────────────┘
```

Firebase is intentionally kept **out of the gameplay authority path**.
It handles identity federation (Google/Email/Guest), push
notifications, and analytics events. Nakama treats a verified Firebase
ID token as one of several supported "custom authentication" inputs,
then issues its own session — Nakama's session, not Firebase's, is
what the authoritative server trusts during a match.

## 3. Architectural Style

We apply **Clean Architecture** adapted to a real-time game engine,
layered as:

| Layer | Responsibility | Lives in |
|---|---|---|
| **Domain** | Pure game rules & data structures, no engine APIs (e.g. `WeaponStats`, `MatchRules`, `InventoryItem`) | `client/features/<feature>/domain/`, `server/modules/<module>/domain/` |
| **Application** | Use-case orchestration (e.g. `FireWeaponUseCase`, `JoinMatchmakingUseCase`) | `.../application/` |
| **Infrastructure** | Engine/IO-bound adapters (Nakama client calls, Firebase SDK, filesystem, DB) | `.../infrastructure/` |
| **Presentation** | Godot scenes/scripts, UI, input handling | `.../presentation/` |

Each feature folder under `client/features/` and `server/modules/`
follows this same four-layer sub-structure once implementation begins.
Presentation may depend on Application and Domain. Application may
depend on Domain only. Domain depends on nothing outside itself. This
is enforced by code review and (from Phase 3 onward) a static import
linter.

### Why this layering for a Godot game specifically

Godot encourages putting logic directly in scene scripts, which is
fine for prototypes but becomes unmaintainable at BR scale (50 players,
dozens of systems, 1+ year roadmap). By keeping `domain/` and
`application/` free of `Node`/`extends` engine coupling, we can:

- Unit test game rules (damage falloff, safe-zone math, loot tables)
  in isolation, at full speed, with no scene tree required.
- Swap the transport layer (e.g. Nakama SDK version bump) without
  touching gameplay rules.
- Reuse `domain/` logic between client-side prediction and
  server-side authoritative modules where languages allow (shared
  TypeScript/GDScript data contracts, mirrored logic).

## 4. Feature-Based Folder Structure

Rather than grouping by technical type (`all scripts/`, `all
scenes/`), we group by **feature vertical**. Every gameplay feature
listed in the project brief maps 1:1 to a folder under
`client/features/` and, where it has server logic, a matching folder
under `server/modules/`:

```
client/features/<feature_name>/
├── domain/
├── application/
├── infrastructure/
├── presentation/
└── README.md        # public interface + dependency contract
```

This keeps blast radius small: a bug or refactor in `weapons/` cannot
silently break `cosmetics/`. Cross-feature communication happens only
through the **Event Bus** (`client/core/events/`) or explicit public
interfaces documented in each feature's `README.md` — never through
direct node lookups (`get_node("../../OtherFeature")`) across feature
boundaries.

## 5. Dependency Injection

Godot's autoload/singleton system is convenient but creates hidden
global coupling if overused. Our rule:

- `client/core/di/` provides a lightweight **Service Locator +
  Container** (`ServiceContainer.gd`), registered as a single
  autoload (`Services`).
- Features register their public services (e.g.
  `InventoryService`, `MatchmakingService`) into the container at
  bootstrap.
- Other features request dependencies through the container in their
  `_ready()`/composition step — never by hardcoding scene tree paths.
- Only `Services` itself is a "true" global autoload. All other
  cross-cutting systems (event bus, save system, network client) are
  registered as services, not autoloads, so they can be mocked in
  tests.

This is documented in full with code once we reach Phase 3 (Core
Framework), where `ServiceContainer.gd` and `EventBus.gd` are
implemented as the first production code in the repo.

## 6. Networking Model (summary — full detail in Phase 5)

- **Dedicated authoritative server** via Nakama's match handler
  runtime (Go or TypeScript module) — server owns all gameplay state.
- **Client-side prediction** for local player movement/shooting,
  reconciled against authoritative snapshots.
- **Interpolation** for remote entities between server ticks.
- **Lag compensation** via server-side rewind for hit registration.
- **Secure RPC validation**: every client → server RPC is schema
  validated and rate-limited server-side; the client is never trusted
  for damage, position deltas beyond tolerance, or economy changes.

## 7. Data Ownership

| Data | Source of truth | Cache/queue |
|---|---|---|
| Identity (login) | Firebase Auth | — |
| Player profile, inventory, stats, match history | PostgreSQL (`warzone_*` tables) | Redis (hot cache) |
| Matchmaking queue, live session/presence | Redis | — |
| In-match simulation state | Nakama match handler (in-memory, authoritative) | — |
| Cosmetic/asset definitions | PostgreSQL (versioned content tables) | Redis / client bundle cache |

**Important:** Nakama's own internal schema and our custom `warzone_*`
tables live in the **same** Postgres database (see
`docs/adr/ADR-0003`). Nakama runtime modules can only reach whatever
database they were started with — there is no cross-database query
path in Postgres — so this is not an optional simplification, it's a
hard constraint on the topology. The two schemas are kept apart only
by table naming convention, not by database boundary.

## 8. Non-Functional Requirements Baked Into Architecture

- **Scalability**: match handlers are stateless-between-matches Nakama
  modules so horizontal scaling is a matter of adding Nakama nodes
  behind the existing matchmaker; no architecture rewrite needed to go
  from 50 → hundreds of concurrent matches.
- **Low-end device support**: all client feature modules must expose a
  "quality tier" hook (Phase 13 — Optimization) so rendering-heavy
  features (vehicles, cosmetics, effects) can degrade gracefully.
- **Testability**: domain/application layers must reach meaningful
  unit test coverage before a feature is marked complete in
  `MILESTONES.md`.
- **Security by default**: anything that changes persistent player
  state must go through `server/modules/`, never trust a client RPC
  payload directly (see `docs/adr/` for anti-cheat ADRs as they land).

## 9. Decisions Made Since Initial Writing

- Match handler language (Go vs. TypeScript): **TypeScript**, with a
  documented trigger for reconsidering Go once real load-testing
  exists — see ADR-0006.
- Voice chat transport (WebRTC via Nakama relay vs. dedicated SFU) —
  still deferred to Phase 12.
- Replay system storage format — architecture still reserves hooks
  (deterministic input/event logging) starting Phase 6, but the replay
  *feature* itself remains scheduled late.

Deferring the still-open items is intentional per the workflow rules:
we do not architect features before their phase, we only leave clean
extension points for them.
