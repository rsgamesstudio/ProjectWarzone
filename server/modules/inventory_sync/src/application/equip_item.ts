import { ownsItem, equipItem } from "../infrastructure/warzone_inventory_db";
import { getCatalogItem, slotKeyFor } from "../domain/item_catalog";

export type EquipItemResult =
  | { success: true; slotKey: string }
  | { success: false; errorCode: "UNKNOWN_ITEM" | "NOT_OWNED"; message: string };

/**
 * Equips `itemId` for `accountId`, deriving the correct slot from the
 * item's own catalog entry (a weapon skin always goes into its
 * weapon's slot; a character skin always goes into the character
 * slot) — the caller never specifies the slot directly, so it's
 * impossible to equip an item into the wrong slot by client mistake
 * or malice.
 */
export function equipInventoryItem(nk: nkruntime.Nakama, accountId: string, itemId: string): EquipItemResult {
  const catalogItem = getCatalogItem(itemId);
  if (!catalogItem) {
    return { success: false, errorCode: "UNKNOWN_ITEM", message: `Unknown item: ${itemId}` };
  }

  if (!ownsItem(nk, accountId, itemId)) {
    return { success: false, errorCode: "NOT_OWNED", message: "You do not own this item." };
  }

  const slotKey = slotKeyFor(catalogItem);
  equipItem(nk, accountId, slotKey, itemId);

  return { success: true, slotKey };
}
