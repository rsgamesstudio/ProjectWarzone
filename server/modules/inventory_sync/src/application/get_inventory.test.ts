import { test } from "node:test";
import assert from "node:assert/strict";
import { getInventory } from "./get_inventory";
import { FakeNakama } from "../test_support/fake_nakama";

test("returns empty inventory and zero balance for a fresh account", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1");

  const result = getInventory(fake.asNk(), "account-1");

  assert.equal(result.credits, 0);
  assert.equal(result.marks, 0);
  assert.deepEqual(result.ownedItems, []);
  assert.deepEqual(result.equippedSlots, {});
});

test("reflects currency balance correctly", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1", 5000, 250);

  const result = getInventory(fake.asNk(), "account-1");

  assert.equal(result.credits, 5000);
  assert.equal(result.marks, 250);
});

test("includes owned items with resolved display names", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1");
  fake.inventoryItems.get("account-1")!.add("skin.assault_rifle.field_issue");

  const result = getInventory(fake.asNk(), "account-1");

  assert.equal(result.ownedItems.length, 1);
  assert.equal(result.ownedItems[0].displayName, "VK-12 Field Issue");
});

test("falls back to the raw item id if it's not in the catalog", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1");
  fake.inventoryItems.get("account-1")!.add("some.unknown.item");

  const result = getInventory(fake.asNk(), "account-1");

  assert.equal(result.ownedItems[0].displayName, "some.unknown.item");
});

test("includes equipped slots", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1");
  fake.loadoutSlots.get("account-1")!.set("weapon_skin:assault_rifle", "skin.assault_rifle.field_issue");

  const result = getInventory(fake.asNk(), "account-1");

  assert.equal(result.equippedSlots["weapon_skin:assault_rifle"], "skin.assault_rifle.field_issue");
});
