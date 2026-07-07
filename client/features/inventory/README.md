# Inventory

**Layer:** Client feature module
**Status:** Implemented (Phase 8) — domain/application logic complete
and tested; presentation (an actual inventory/loadout UI screen) is
not yet built.

## Responsibility

Persistent inventory state: currency balances (Credits/Marks), owned
cosmetic items, and equipped loadout slots. Match-local loot (Phase 10)
is separate and ephemeral — not this feature's concern.

## Structure

- `domain/inventory_item.gd` — one owned item (pure data)
- `domain/inventory_view.gd` — the full inventory view + `from_dict()` parser for the `get_inventory` RPC response
- `application/inventory_service.gd` — orchestrates fetch/equip/purchase, caches the current view

## Depends On

- `client/networking/nakama_client` (`get_inventory_async`, `equip_item_async`, `purchase_item_async`)

## Public Interface

- `InventoryService.fetch_inventory_async() -> InventoryView`
- `InventoryService.equip_item_async(item_id) -> Dictionary`
- `InventoryService.purchase_item_async(item_id) -> Dictionary`
- `InventoryService.current_view` (cached, readonly by convention)

## Tests

- `client/tests/unit/features/inventory/test_inventory_view.gd` (3 cases)
- `client/tests/unit/features/inventory/test_inventory_service.gd` (7 cases, using a fake `NakamaClientAdapter`)

## Notes

**Not yet built**: the actual inventory/loadout/store UI screen, and
wiring the lobby's currency display to real data instead of
`MockLobbyDataProvider` (Phase 4's mock). That wiring needs a session
carried from the login screen through to the lobby, which doesn't
exist yet — a reasonable Phase 9 (UI System) integration task rather
than something to half-wire here.

See `server/modules/inventory_sync/README.md` for the authoritative
server-side counterpart (item catalog, starter-item provisioning,
purchase validation).
