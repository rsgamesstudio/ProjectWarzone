# Cosmetics

**Layer:** Client feature module
**Status:** Not implemented (scheduled: Phase 8)

## Responsibility

Character/weapon skin selection, preview, and application. Cosmetic definitions are data-driven (no gameplay effect) to keep balance server-authoritative and cosmetic content swappable.

## Depends On

- `client/features/inventory`

## Public Interface (planned)

- `CosmeticService.equip_skin(item_id)`
- `CosmeticService.preview(item_id)`

## Notes

All cosmetic assets must be original or open-license per project rules.
