import { ownsItem, grantItem, tryDeductMarks } from "../infrastructure/warzone_inventory_db";
import { getCatalogItem } from "../domain/item_catalog";

export type PurchaseItemResult =
  | { success: true; itemId: string; marksSpent: number }
  | { success: false; errorCode: "UNKNOWN_ITEM" | "ALREADY_OWNED" | "INSUFFICIENT_FUNDS"; message: string };

export function purchaseItem(nk: nkruntime.Nakama, accountId: string, itemId: string): PurchaseItemResult {
  const catalogItem = getCatalogItem(itemId);
  if (!catalogItem) {
    return { success: false, errorCode: "UNKNOWN_ITEM", message: `Unknown item: ${itemId}` };
  }

  if (ownsItem(nk, accountId, itemId)) {
    return { success: false, errorCode: "ALREADY_OWNED", message: "You already own this item." };
  }

  // Free (default) items should be granted via provisioning, not
  // "purchased" — but if this is ever called for a free item anyway,
  // handle it correctly rather than erroring.
  if (catalogItem.costMarks > 0) {
    const deducted = tryDeductMarks(nk, accountId, catalogItem.costMarks);
    if (!deducted) {
      return { success: false, errorCode: "INSUFFICIENT_FUNDS", message: "Not enough Marks for this purchase." };
    }
  }

  grantItem(nk, accountId, itemId);

  return { success: true, itemId, marksSpent: catalogItem.costMarks };
}
