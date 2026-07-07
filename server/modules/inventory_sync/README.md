# Inventory Sync Module

**Layer:** Nakama server module
**Status:** Implemented (Phase 8)

## Responsibility

Currency balances (Credits/Marks), owned cosmetic items, and equipped
loadout slots — all persisted to the same Postgres database Nakama
itself uses (migration 0003, per ADR-0003). Validates all
economy-affecting requests server-side; never trusts a client-declared
grant.

## Structure

- `domain/item_catalog.ts` — the cosmetic item catalog (original names — same family of decisions as ADR-0007)
- `application/get_inventory.ts` — builds the full inventory view
- `application/equip_item.ts` — validates ownership, derives the correct slot from the item itself (a client can never equip an item into the wrong slot)
- `application/purchase_item.ts` — validates funds, atomically deducts Marks, grants the item
- `application/provision_starter_items.ts` — grants + equips default items on first login
- `infrastructure/warzone_inventory_db.ts` — SQL access for the new tables
- `index.ts` — registers hooks + RPCs

## Cross-Module Design Note

This module registers its **own** `registerAfterAuthenticateDevice/
Email/Custom` hooks, independent of `server/modules/authentication`'s.
This assumes Nakama invokes every registered after-hook for a given
event across all loaded modules, not just the first one registered —
the standard multi-module Nakama pattern, but **not verified against a
running Nakama instance** in the sandbox this was built in. Confirm
both modules' hooks actually fire on login before relying on this in
production — see the PHASE_08 report's testing checklist.

## Depends On

- PostgreSQL (`warzone_accounts.credits/marks`, `warzone_inventory_items`, `warzone_loadout_slots` — migration 0003)
- Cannot import `server/modules/authentication`'s TS source directly (separate bundled module) — duplicates one small "find account by Nakama user ID" query instead; see `warzone_inventory_db.ts`'s docstring

## Public Interface

- RPC `get_inventory` — returns `{credits, marks, ownedItems: [...], equippedSlots: {...}}`
- RPC `equip_item` — payload `{"itemId": string}`, returns `{"success": true, "slotKey": string}` or `{"success": false, "errorCode": "UNKNOWN_ITEM"|"NOT_OWNED", "message": string}`
- RPC `purchase_item` — payload `{"itemId": string}`, returns `{"success": true, "itemId": string, "marksSpent": number}` or `{"success": false, "errorCode": "UNKNOWN_ITEM"|"ALREADY_OWNED"|"INSUFFICIENT_FUNDS", "message": string}`

## Tests

- `npm test`: 28 tests — 7 domain (item catalog, including a
  branded-skin-name regression guard), 20 application (5 get_inventory,
  5 equip_item, 5 purchase_item, 5 provision_starter_items — using an
  in-memory fake of the SQL functions), 1 wiring smoke test
- `npm run typecheck` — clean against the vendored Nakama runtime types
- `npm run build` — bundle verified to attach a global `InitModule` correctly

## Notes

`purchase_item`'s Marks deduction uses a single `UPDATE ... WHERE
marks >= $2 RETURNING id` statement specifically to avoid a race
between a separate balance-check read and a later deduct write — see
`tryDeductMarks`'s docstring in `warzone_inventory_db.ts`.
