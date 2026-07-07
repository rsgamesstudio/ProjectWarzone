# Phase 3 — Core Framework

## Goal

Write the first real production GDScript in the repo: the two
sanctioned autoloads (`Services`, `Bootstrap`) and the Event Bus they
wire together, plus a real automated test suite so every future phase
has regression protection instead of relying on manual checklists
alone.

## What Was Built

1. **`ServiceContainer`** (`client/core/di/service_container.gd`,
   autoload `Services`) — register/resolve/has_service/unregister/
   clear_all/registered_keys. Double-registration without an explicit
   `allow_override=true` is rejected with a pushed error rather than
   silently overwritten, to surface startup-ordering bugs early.
2. **`GameEvent`** (`client/core/events/game_event.gd`) — base class
   every feature's event types will extend, auto-timestamping on
   construction.
3. **`EventBus`** (`client/core/events/event_bus.gd`) — publish/
   subscribe/unsubscribe/clear/subscriber_count, keyed by exact event
   script type. Not an autoload itself — instantiated once by
   `Bootstrap` and registered into `Services` under `"EventBus"`, per
   ARCHITECTURE.md §5.
4. **`Bootstrap`** (`client/core/autoload/bootstrap.gd`, autoload
   `Bootstrap`) — constructs the `EventBus` and registers it. Kept
   deliberately minimal; explicitly documented as the wrong place for
   feature-specific startup logic.
5. **Autoloads registered** in `client/project.godot` in dependency
   order (`Services` before `Bootstrap`).
6. **GUT (Godot Unit Test) v9.3.0 vendored** into
   `client/addons/gut/` (MIT licensed, see `VENDORED.md`) and enabled
   as an editor plugin, giving the project a real automated test
   runner instead of manual-only checklists from this phase onward.
7. **19 automated tests**:
   - 7 unit tests for `ServiceContainer` (isolated instance, not the
     autoload — see CODING_STANDARDS.md testing policy)
   - 9 unit tests for `EventBus` (isolated instance, using two
     test-only fixture event types under `tests/unit/core/fixtures/`)
   - 3 integration tests exercising the *real* `Services`/`Bootstrap`
     autoloads to catch autoload-order regressions unit tests can't see
8. **`tools/build-scripts/run_gdscript_tests.sh`** — headless GUT
   runner, wired into a new CI job (`run-gdscript-tests`).

## Design Notes

- `EventBus.publish()` deliberately does not catch exceptions thrown
  by subscriber callbacks — a bug in a handler should fail loudly
  during development, not be silently absorbed.
- `EventBus` iterates a shallow copy of its subscriber list during
  publish so a handler unsubscribing itself mid-dispatch can't corrupt
  iteration.
- Test fixture event types (`GutFixtureEventA`/`B`) live under
  `tests/` specifically so they can never be mistaken for real
  gameplay events by a future contributor skimming `core/events/`.

## Explicitly Out of Scope This Phase

- Any feature-specific event types (each feature defines its own
  `GameEvent` subclasses when that feature is built)
- Firebase/Nakama session wiring (Phase 4)
- Anything touching the scene tree beyond autoloads (character
  controller, UI, etc. — later phases)

## Testing Checklist

- [ ] Open the project in Godot 4.3+; the editor loads with no script
      errors and the GUT panel is available (bottom dock)
- [ ] Run `./tools/build-scripts/run_gdscript_tests.sh` — all 19 tests
      pass
- [ ] In the Godot editor console at startup, confirm the log line
      `[Bootstrap] Core services registered: ["EventBus"]`
- [ ] Manually call `Services.resolve("NotRegistered")` from a test
      scene and confirm it logs an error and returns null rather than
      crashing
- [ ] Manually call `Services.register("EventBus", Node.new())` a
      second time without `allow_override` and confirm it's rejected
      (original instance still resolves)

## Next Milestone

**Phase 4 — Authentication**: Firebase Guest/Google/Email login on the
client, `server/modules/authentication` Nakama bridge, and the
nickname claim transaction from ADR-0002 implemented end-to-end
against the `warzone_accounts`/`warzone_nicknames` tables from Phase 2.

## Estimated Completion

**~6%** of overall project (Phase 3 of 16 complete).
