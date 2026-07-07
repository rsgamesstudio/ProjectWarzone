import { getDefaultItems, slotKeyFor } from "../domain/item_catalog";
import { grantItem, equipItem, getEquippedSlots, findAccountIdByNakamaUserId } from "../infrastructure/warzone_inventory_db";

/**
 * Grants every default catalog item and equips each into its slot.
 * Idempotent — safe to call on every login, not just the first,
 * since `grantItem` is idempotent (ON CONFLICT DO NOTHING) and
 * equipping only happens for slots that aren't already filled (so a
 * player who unequipped their starter skin never has it silently
 * re-equipped over their choice).
 */
export function provisionStarterItemsIfNeeded(nk: nkruntime.Nakama, nakamaUserId: string): void {
  const accountId = findAccountIdByNakamaUserId(nk, nakamaUserId);
  if (!accountId) {
    // The authentication module's own after-hook is what creates the
    // warzone_accounts row in the first place (see ADR-0004); if it
    // hasn't run yet for some reason, there's nothing for us to
    // provision against yet. Not an error — just nothing to do.
    return;
  }

  const alreadyEquipped = getEquippedSlots(nk, accountId);

  for (const item of getDefaultItems()) {
    grantItem(nk, accountId, item.id);

    const slotKey = slotKeyFor(item);
    if (!alreadyEquipped[slotKey]) {
      equipItem(nk, accountId, slotKey, item.id);
    }
  }
}
