/**
 * Cosmetic item catalog. All names are original — consistent with
 * this project's blanket rule against copying names from existing
 * titles (same family of decisions as ADR-0005/ADR-0007). Pure data,
 * no Nakama dependency.
 */

export type ItemSlotType = "weapon_skin" | "character_skin";

export interface CatalogItem {
  id: string;
  slotType: ItemSlotType;
  /** Only present for weapon_skin items — which weapon class this skin applies to. */
  weaponClass?: string;
  displayName: string;
  costMarks: number;
  /** Auto-granted to every new account (see application/provision_starter_items.ts). */
  isDefault: boolean;
}

export const CATALOG: Record<string, CatalogItem> = {
  // Default (free, auto-granted) weapon skins — one per weapon class.
  "skin.assault_rifle.field_issue": {
    id: "skin.assault_rifle.field_issue",
    slotType: "weapon_skin",
    weaponClass: "assault_rifle",
    displayName: "VK-12 Field Issue",
    costMarks: 0,
    isDefault: true,
  },
  "skin.smg.field_issue": {
    id: "skin.smg.field_issue",
    slotType: "weapon_skin",
    weaponClass: "smg",
    displayName: "Wisp SMG Field Issue",
    costMarks: 0,
    isDefault: true,
  },
  "skin.sniper.field_issue": {
    id: "skin.sniper.field_issue",
    slotType: "weapon_skin",
    weaponClass: "sniper",
    displayName: "Longbow Field Issue",
    costMarks: 0,
    isDefault: true,
  },
  "skin.shotgun.field_issue": {
    id: "skin.shotgun.field_issue",
    slotType: "weapon_skin",
    weaponClass: "shotgun",
    displayName: "Reaper-12 Field Issue",
    costMarks: 0,
    isDefault: true,
  },
  "skin.sidearm.field_issue": {
    id: "skin.sidearm.field_issue",
    slotType: "weapon_skin",
    weaponClass: "sidearm",
    displayName: "Talon Pistol Field Issue",
    costMarks: 0,
    isDefault: true,
  },

  // Premium (purchasable with Marks) weapon skins.
  "skin.assault_rifle.nightfall": {
    id: "skin.assault_rifle.nightfall",
    slotType: "weapon_skin",
    weaponClass: "assault_rifle",
    displayName: "VK-12 Nightfall",
    costMarks: 800,
    isDefault: false,
  },
  "skin.smg.voltage": {
    id: "skin.smg.voltage",
    slotType: "weapon_skin",
    weaponClass: "smg",
    displayName: "Wisp SMG Voltage",
    costMarks: 700,
    isDefault: false,
  },
  "skin.sniper.ashwood": {
    id: "skin.sniper.ashwood",
    slotType: "weapon_skin",
    weaponClass: "sniper",
    displayName: "Longbow Ashwood",
    costMarks: 900,
    isDefault: false,
  },

  // Character skins.
  "character.rs_operator": {
    id: "character.rs_operator",
    slotType: "character_skin",
    displayName: "RS Operator",
    costMarks: 0,
    isDefault: true,
  },
  "character.nightfall_operator": {
    id: "character.nightfall_operator",
    slotType: "character_skin",
    displayName: "Nightfall Operator",
    costMarks: 1200,
    isDefault: false,
  },
};

export function getCatalogItem(itemId: string): CatalogItem | null {
  return CATALOG[itemId] ?? null;
}

export function getDefaultItems(): CatalogItem[] {
  return Object.values(CATALOG).filter((item) => item.isDefault);
}

export function slotKeyFor(item: CatalogItem): string {
  if (item.slotType === "weapon_skin") {
    return `weapon_skin:${item.weaponClass}`;
  }
  return "character_skin";
}
