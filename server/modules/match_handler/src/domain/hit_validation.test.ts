import { test } from "node:test";
import assert from "node:assert/strict";
import { validateHitPlausibility } from "./hit_validation";
import { getWeaponDefinition } from "./weapon_definitions";
import type { Vector3 } from "./movement_validation";

const rifle = getWeaponDefinition("assault_rifle"); // maxRange 120, fireRate 8/s
const ORIGIN: Vector3 = { x: 0, y: 0, z: 0 };

test("accepts a plausible hit at matching distance with no prior shot", () => {
  const target: Vector3 = { x: 50, y: 0, z: 0 };
  const result = validateHitPlausibility(ORIGIN, target, 50, rifle, null);
  assert.equal(result.plausible, true);
});

test("rejects a claim beyond the weapon's max range", () => {
  const target: Vector3 = { x: 500, y: 0, z: 0 };
  const result = validateHitPlausibility(ORIGIN, target, 500, rifle, null);
  assert.equal(result.plausible, false);
});

test("rejects when claimed distance does not match actual positions", () => {
  const target: Vector3 = { x: 50, y: 0, z: 0 };
  // Actual distance is 50m, but the claim says 10m — a mismatch far
  // beyond the tolerance, suggesting a spoofed claim.
  const result = validateHitPlausibility(ORIGIN, target, 10, rifle, null);
  assert.equal(result.plausible, false);
});

test("accepts small distance discrepancies within tolerance", () => {
  const target: Vector3 = { x: 50, y: 0, z: 0 };
  const result = validateHitPlausibility(ORIGIN, target, 51.5, rifle, null);
  assert.equal(result.plausible, true);
});

test("rejects firing faster than the weapon's fire rate", () => {
  const target: Vector3 = { x: 10, y: 0, z: 0 };
  // Rifle fires 8/s => minimum ~0.125s between shots (with tolerance ~0.106s).
  const result = validateHitPlausibility(ORIGIN, target, 10, rifle, 0.02);
  assert.equal(result.plausible, false);
});

test("accepts firing at a legitimate interval", () => {
  const target: Vector3 = { x: 10, y: 0, z: 0 };
  const result = validateHitPlausibility(ORIGIN, target, 10, rifle, 0.5);
  assert.equal(result.plausible, true);
});

test("first shot ever (no prior fire tick) is not rate-limited", () => {
  const target: Vector3 = { x: 10, y: 0, z: 0 };
  const result = validateHitPlausibility(ORIGIN, target, 10, rifle, null);
  assert.equal(result.plausible, true);
});
