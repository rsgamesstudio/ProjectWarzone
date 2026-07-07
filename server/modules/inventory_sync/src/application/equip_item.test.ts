import { test } from "node:test";
import assert from "node:assert/strict";
import { equipInventoryItem } from "./equip_item";
import { FakeNakama } from "../test_support/fake_nakama";

test("equips an owned item successfully", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1");
  fake.inventoryItems.get("account-1")!.add("skin.assault_rifle.field_issue");

  const result = equipInventoryItem(fake.asNk(), "account-1", "skin.assault_rifle.field_issue");

  assert.equal(result.success, true);
  if (result.success) {
    assert.equal(result.slotKey, "weapon_skin:assault_rifle");
  }
  assert.equal(fake.loadoutSlots.get("account-1")!.get("weapon_skin:assault_rifle"), "skin.assault_rifle.field_issue");
});

test("rejects equipping an item that is not owned", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1");

  const result = equipInventoryItem(fake.asNk(), "account-1", "skin.assault_rifle.field_issue");

  assert.equal(result.success, false);
  if (!result.success) {
    assert.equal(result.errorCode, "NOT_OWNED");
  }
});

test("rejects equipping an unknown item id", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1");

  const result = equipInventoryItem(fake.asNk(), "account-1", "does.not.exist");

  assert.equal(result.success, false);
  if (!result.success) {
    assert.equal(result.errorCode, "UNKNOWN_ITEM");
  }
});

test("equipping a new weapon skin replaces the previously equipped one in the same slot", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1");
  fake.inventoryItems.get("account-1")!.add("skin.assault_rifle.field_issue");
  fake.inventoryItems.get("account-1")!.add("skin.assault_rifle.nightfall");

  equipInventoryItem(fake.asNk(), "account-1", "skin.assault_rifle.field_issue");
  equipInventoryItem(fake.asNk(), "account-1", "skin.assault_rifle.nightfall");

  assert.equal(fake.loadoutSlots.get("account-1")!.get("weapon_skin:assault_rifle"), "skin.assault_rifle.nightfall");
  assert.equal(fake.loadoutSlots.get("account-1")!.size, 1, "equipping a second item in the same slot should replace, not add a second entry");
});

test("weapon skins and character skins occupy independent slots", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1");
  fake.inventoryItems.get("account-1")!.add("skin.assault_rifle.field_issue");
  fake.inventoryItems.get("account-1")!.add("character.rs_operator");

  equipInventoryItem(fake.asNk(), "account-1", "skin.assault_rifle.field_issue");
  equipInventoryItem(fake.asNk(), "account-1", "character.rs_operator");

  assert.equal(fake.loadoutSlots.get("account-1")!.size, 2);
});
