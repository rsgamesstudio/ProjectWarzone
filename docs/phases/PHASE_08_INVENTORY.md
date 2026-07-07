# Phase 8 — Inventory

## Goal

Client + server inventory sync: currency (Credits/Marks) becoming
real instead of the lobby's mock data, an original cosmetic item
catalog, starter-item provisioning on first login, and equip/purchase
RPCs.

## What Was Built

### Server (`server/modules/inventory_sync/` — new module)
- `item_catalog.ts` — original cosmetic items: a free "Field Issue"
  skin per weapon class (auto-granted), a few premium skins, and two
  character skins (one free, one premium — "Nightfall Operator" ties
  back to the lobby's "Nightfall Bundle" naming from Phase 6)
- `get_inventory.ts` / `equip_item.ts` / `purchase_item.ts` —
  application use cases; `equip_item` derives the correct slot from
  the item itself, so a client can never equip something into the
  wrong slot
- `provision_starter_items.ts` — idempotent starter-item grant/equip
  on login, careful not to silently re-equip over a player's own
  later equip choice
- Migration 0003: `credits`/`marks` columns on `warzone_accounts`,
  plus `warzone_inventory_items` and `warzone_loadout_slots` tables

### Client (`client/features/inventory/`)
- `InventoryView`/`InventoryItem` — parsed domain data from the
  `get_inventory` RPC response
- `InventoryService` — fetch/equip/purchase orchestration with a
  locally cached view, updated optimistically on success
- `NakamaClientAdapter` gained `get_inventory_async`/
  `equip_item_async`/`purchase_item_async`, and was refactored to
  share a `_call_rpc_json()` helper across all its RPC methods (the
  third near-duplicate RPC method made the duplication worth removing)

## An Architectural Question Worth Flagging Honestly

`inventory_sync` needs to react to account creation, but it's a
**separate Nakama module** from `authentication` — modules can't
import each other's TypeScript source (each is its own independently
bundled `InitModule`). The design taken: `inventory_sync` registers
its **own** copy of the `registerAfterAuthenticateDevice/Email/Custom`
hooks, on the assumption that Nakama calls every registered after-hook
for a given event across all loaded modules, not just the first one
registered. This is the standard multi-module Nakama pattern, but **it
could not be verified against a running Nakama instance** in this
sandbox (no Go toolchain, no live Nakama to test hook-chaining
against). This is called out explicitly in
`server/modules/inventory_sync/README.md` and the testing checklist
below — confirm both modules' hooks actually fire before relying on
this in production.

## Verification Performed

- **Server:** `tsc --noEmit` clean, 28/28 tests passing (7 domain, 20
  application using an in-memory fake of the SQL functions, 1 wiring
  smoke test), esbuild bundle verified to load and attach `InitModule`
  correctly. One real design flaw was caught and fixed while writing
  `tryDeductMarks`: the first draft did a deduct-then-reread pattern
  that didn't actually verify anything meaningful — replaced with a
  single atomic `UPDATE ... RETURNING` statement.
- **Client:** 10 new unit tests for `InventoryView` parsing and
  `InventoryService` orchestration, using a fake `NakamaClientAdapter`
  (same fixture pattern as every prior phase). Reviewed structurally,
  not executed — still no Godot binary in this sandbox.

## Explicitly Out of Scope This Phase

- Any inventory/loadout/store UI screen (presentation layer)
- Wiring the lobby's currency display to real data (needs a session
  carried from login through to the lobby — reasonable Phase 9 work)
- Attachments (Phase 7 mentioned them; not built yet — tracked as open)
- Admin/moderation tooling for granting items outside normal purchase flow

## Testing Checklist

**Server (verifiable by running the commands below):**
- [ ] `cd server/modules/inventory_sync && npm install && npm run typecheck && npm test` — 28/28 pass
- [ ] `npm run build` — produces `build/index.js`
- [ ] **Critical, unverified-in-sandbox check**: full stack up, log in
      as a fresh guest, call `get_inventory` — confirm starter items
      were actually granted (this only works if Nakama really does
      call both `authentication`'s and `inventory_sync`'s
      after-hooks — see the architectural note above)
- [ ] Call `purchase_item` for a premium skin with sufficient Marks →
      success, balance decreases, item appears in `get_inventory`
- [ ] Call `purchase_item` with insufficient Marks → `INSUFFICIENT_FUNDS`, no balance change
- [ ] Call `equip_item` for an owned item → succeeds; for a not-owned item → `NOT_OWNED`

**Client (requires a real Godot 4.3+ editor):**
- [ ] `./tools/build-scripts/run_gdscript_tests.sh` — all tests pass, including the 10 new inventory cases

## Next Milestone

**Phase 9 — UI System**: shared UI framework (theme, reusable
widgets, HUD composition root, menu navigation stack) — also the
natural point to wire real `InventoryService`/`AuthService` data into
the lobby instead of the Phase 4 mock.

## Estimated Completion

**~21%** of overall project (Phase 8 of 16 complete).
