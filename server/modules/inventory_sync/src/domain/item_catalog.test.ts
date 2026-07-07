import { test } from "node:test";
import assert from "node:assert/strict";
import { getCatalogItem, getDefaultItems, slotKeyFor, CATALOG } from "./item_catalog";

test("getCatalogItem returns a known item", () => {
  const item = getCatalogItem("skin.assault_rifle.field_issue");
  assert.ok(item);
  assert.equal(item?.displayName, "VK-12 Field Issue");
});

test("getCatalogItem returns null for an unknown item", () => {
  assert.equal(getCatalogItem("does.not.exist"), null);
});

test("getDefaultItems returns only isDefault items", () => {
  const defaults = getDefaultItems();
  assert.ok(defaults.length > 0);
  for (const item of defaults) {
    assert.equal(item.isDefault, true);
  }
});

test("every weapon class has exactly one default skin", () => {
  const weaponClasses = ["assault_rifle", "smg", "sniper", "shotgun", "sidearm"];
  const defaults = getDefaultItems().filter((i) => i.slotType === "weapon_skin");
  for (const weaponClass of weaponClasses) {
    const matches = defaults.filter((i) => i.weaponClass === weaponClass);
    assert.equal(matches.length, 1, `expected exactly one default skin for ${weaponClass}`);
  }
});

test("slotKeyFor derives the correct slot for a weapon skin", () => {
  const item = getCatalogItem("skin.assault_rifle.field_issue")!;
  assert.equal(slotKeyFor(item), "weapon_skin:assault_rifle");
});

test("slotKeyFor derives the correct slot for a character skin", () => {
  const item = getCatalogItem("character.rs_operator")!;
  assert.equal(slotKeyFor(item), "character_skin");
});

test("no catalog item name references a real cosmetic/skin name from an existing title", () => {
  // Lightweight regression guard, same family as ADR-0005/ADR-0007's
  // existing tests — catches an accidental copy-paste of a real
  // branded skin name back into this catalog.
  const forbidden = ["Damascus", "Dragon", "Golden AK", "Nomad", "Legendary Bundle"];
  for (const item of Object.values(CATALOG)) {
    for (const name of forbidden) {
      assert.ok(!item.displayName.includes(name), `${item.displayName} should not reference ${name}`);
    }
  }
});
