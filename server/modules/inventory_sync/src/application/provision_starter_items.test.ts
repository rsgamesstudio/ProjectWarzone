import { test } from "node:test";
import assert from "node:assert/strict";
import { provisionStarterItemsIfNeeded } from "./provision_starter_items";
import { getDefaultItems } from "../domain/item_catalog";
import { FakeNakama } from "../test_support/fake_nakama";

test("grants every default item on first call", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1");

  provisionStarterItemsIfNeeded(fake.asNk(), "user-1");

  const owned = fake.inventoryItems.get("account-1")!;
  for (const item of getDefaultItems()) {
    assert.ok(owned.has(item.id), `expected default item ${item.id} to be granted`);
  }
});

test("equips every default item into its slot", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1");

  provisionStarterItemsIfNeeded(fake.asNk(), "user-1");

  const slots = fake.loadoutSlots.get("account-1")!;
  assert.equal(slots.get("weapon_skin:assault_rifle"), "skin.assault_rifle.field_issue");
  assert.equal(slots.get("character_skin"), "character.rs_operator");
});

test("does not silently re-equip over a player's own equip choice", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1");
  provisionStarterItemsIfNeeded(fake.asNk(), "user-1");

  // Player then equips a different (already-owned) item into the same slot.
  fake.inventoryItems.get("account-1")!.add("skin.assault_rifle.nightfall");
  fake.loadoutSlots.get("account-1")!.set("weapon_skin:assault_rifle", "skin.assault_rifle.nightfall");

  // Calling provisioning again (e.g. on a later login) must not stomp that choice.
  provisionStarterItemsIfNeeded(fake.asNk(), "user-1");

  assert.equal(fake.loadoutSlots.get("account-1")!.get("weapon_skin:assault_rifle"), "skin.assault_rifle.nightfall");
});

test("is a no-op when no account exists yet for the given nakama user id", () => {
  const fake = new FakeNakama();
  // Deliberately not calling fake.addAccount — simulates the
  // authentication module's hook not having run yet.
  provisionStarterItemsIfNeeded(fake.asNk(), "unknown-user");
  // Should not throw, and there's nothing to assert beyond that.
  assert.ok(true);
});

test("calling twice does not duplicate inventory entries", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1");

  provisionStarterItemsIfNeeded(fake.asNk(), "user-1");
  provisionStarterItemsIfNeeded(fake.asNk(), "user-1");

  const owned = fake.inventoryItems.get("account-1")!;
  assert.equal(owned.size, getDefaultItems().length, "a Set can't duplicate, but this confirms idempotency at the count level too");
});
