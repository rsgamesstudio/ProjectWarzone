import { test } from "node:test";
import assert from "node:assert/strict";
import { calculateDamage } from "./damage_calculator";
import { getWeaponDefinition } from "./weapon_definitions";

const rifle = getWeaponDefinition("assault_rifle");

test("full base damage within falloff start range", () => {
  const damage = calculateDamage(rifle, 5);
  assert.equal(damage, rifle.baseDamage);
});

test("full base damage exactly at falloff start boundary", () => {
  const damage = calculateDamage(rifle, rifle.falloffStartMeters);
  assert.equal(damage, rifle.baseDamage);
});

test("minimum damage at or beyond falloff end", () => {
  const damage = calculateDamage(rifle, rifle.falloffEndMeters);
  assert.equal(damage, rifle.baseDamage * rifle.minDamageFraction);
});

test("minimum damage far beyond falloff end", () => {
  const damage = calculateDamage(rifle, rifle.falloffEndMeters + 1000);
  assert.equal(damage, rifle.baseDamage * rifle.minDamageFraction);
});

test("damage decreases monotonically through the falloff range", () => {
  const near = calculateDamage(rifle, rifle.falloffStartMeters + 5);
  const mid = calculateDamage(rifle, (rifle.falloffStartMeters + rifle.falloffEndMeters) / 2);
  const far = calculateDamage(rifle, rifle.falloffEndMeters - 5);
  assert.ok(near > mid, "damage should decrease as distance increases");
  assert.ok(mid > far, "damage should decrease as distance increases");
});

test("halfway through falloff range gives roughly halfway damage", () => {
  const midpoint = (rifle.falloffStartMeters + rifle.falloffEndMeters) / 2;
  const damage = calculateDamage(rifle, midpoint);
  const expectedMidDamage = (rifle.baseDamage + rifle.baseDamage * rifle.minDamageFraction) / 2;
  assert.ok(Math.abs(damage - expectedMidDamage) < 0.01);
});

test("shotgun has severe close-range falloff by design", () => {
  const shotgun = getWeaponDefinition("shotgun");
  const closeDamage = calculateDamage(shotgun, 2);
  const farDamage = calculateDamage(shotgun, shotgun.falloffEndMeters);
  assert.ok(closeDamage > farDamage * 2, "shotgun should lose most of its damage at range");
});
