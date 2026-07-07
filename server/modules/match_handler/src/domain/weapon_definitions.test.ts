import { test } from "node:test";
import assert from "node:assert/strict";
import { getWeaponDefinition, WEAPON_DEFINITIONS } from "./weapon_definitions";

test("all five weapon classes are defined", () => {
  const ids = Object.keys(WEAPON_DEFINITIONS);
  assert.equal(ids.length, 5);
});

test("getWeaponDefinition returns the correct display name", () => {
  const rifle = getWeaponDefinition("assault_rifle");
  assert.equal(rifle.displayName, "VK-12");
});

test("getWeaponDefinition throws for an unknown weapon class", () => {
  // @ts-expect-error deliberately passing an invalid value to test the runtime guard
  assert.throws(() => getWeaponDefinition("does_not_exist"));
});

test("no weapon uses a real firearm manufacturer name", () => {
  // Regression guard tied to ADR-0007.
  const forbidden = ["AK-47", "M4A1", "M16", "AWP", "Barrett", "Glock", "Kalashnikov"];
  for (const weapon of Object.values(WEAPON_DEFINITIONS)) {
    for (const name of forbidden) {
      assert.ok(!weapon.displayName.includes(name), `${weapon.displayName} should not reference ${name}`);
    }
  }
});
