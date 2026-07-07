import { test } from "node:test";
import assert from "node:assert/strict";
import { purchaseItem } from "./purchase_item";
import { FakeNakama } from "../test_support/fake_nakama";

test("purchases an item successfully when funds are sufficient", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1", 0, 1000);

  const result = purchaseItem(fake.asNk(), "account-1", "skin.assault_rifle.nightfall"); // costs 800

  assert.equal(result.success, true);
  if (result.success) {
    assert.equal(result.marksSpent, 800);
  }
  assert.equal(fake.accounts.get("account-1")!.marks, 200);
  assert.ok(fake.inventoryItems.get("account-1")!.has("skin.assault_rifle.nightfall"));
});

test("rejects purchase with insufficient funds and grants nothing", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1", 0, 100);

  const result = purchaseItem(fake.asNk(), "account-1", "skin.assault_rifle.nightfall"); // costs 800

  assert.equal(result.success, false);
  if (!result.success) {
    assert.equal(result.errorCode, "INSUFFICIENT_FUNDS");
  }
  assert.equal(fake.accounts.get("account-1")!.marks, 100, "balance must not change on a failed purchase");
  assert.ok(!fake.inventoryItems.get("account-1")!.has("skin.assault_rifle.nightfall"));
});

test("rejects purchasing an already-owned item", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1", 0, 1000);
  fake.inventoryItems.get("account-1")!.add("skin.assault_rifle.nightfall");

  const result = purchaseItem(fake.asNk(), "account-1", "skin.assault_rifle.nightfall");

  assert.equal(result.success, false);
  if (!result.success) {
    assert.equal(result.errorCode, "ALREADY_OWNED");
  }
  assert.equal(fake.accounts.get("account-1")!.marks, 1000, "must not be charged again for an already-owned item");
});

test("rejects purchasing an unknown item id", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1", 0, 1000);

  const result = purchaseItem(fake.asNk(), "account-1", "does.not.exist");

  assert.equal(result.success, false);
  if (!result.success) {
    assert.equal(result.errorCode, "UNKNOWN_ITEM");
  }
});

test("purchasing a free item (cost 0) succeeds without touching balance", () => {
  const fake = new FakeNakama();
  fake.addAccount("account-1", "user-1", 0, 50);

  const result = purchaseItem(fake.asNk(), "account-1", "skin.assault_rifle.field_issue"); // default, cost 0

  assert.equal(result.success, true);
  assert.equal(fake.accounts.get("account-1")!.marks, 50);
});
