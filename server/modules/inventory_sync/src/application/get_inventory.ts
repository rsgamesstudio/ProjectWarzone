import { getOwnedItems, getEquippedSlots, getCurrencyBalance } from "../infrastructure/warzone_inventory_db";
import { getCatalogItem } from "../domain/item_catalog";

export interface InventoryView {
  credits: number;
  marks: number;
  ownedItems: { itemId: string; displayName: string; acquiredAt: string }[];
  equippedSlots: { [slotKey: string]: string };
}

export function getInventory(nk: nkruntime.Nakama, accountId: string): InventoryView {
  const owned = getOwnedItems(nk, accountId);
  const balance = getCurrencyBalance(nk, accountId);
  const equipped = getEquippedSlots(nk, accountId);

  return {
    credits: balance.credits,
    marks: balance.marks,
    ownedItems: owned.map((item) => {
      const catalogEntry = getCatalogItem(item.itemId);
      return {
        itemId: item.itemId,
        displayName: catalogEntry?.displayName ?? item.itemId,
        acquiredAt: item.acquiredAt,
      };
    }),
    equippedSlots: equipped,
  };
}
