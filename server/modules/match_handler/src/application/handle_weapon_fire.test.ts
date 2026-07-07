import { test } from "node:test";
import assert from "node:assert/strict";
import { handleWeaponFire } from "./handle_weapon_fire";
import type { PlayerMatchState } from "../domain/match_state";

const TICK_RATE = 10;

function makePlayer(overrides: Partial<PlayerMatchState> = {}): PlayerMatchState {
  return {
    userId: "player-1",
    username: "RS_GAMER",
    position: { x: 0, y: 0, z: 0 },
    connected: true,
    lastUpdateTick: 0,
    health: 100,
    eliminated: false,
    lastFireTickByWeapon: {},
    ...overrides,
  };
}

test("accepts a plausible shot and applies damage", () => {
  const shooter = makePlayer({ userId: "shooter" });
  const target = makePlayer({ userId: "target", position: { x: 50, y: 0, z: 0 }, health: 100 });

  const result = handleWeaponFire(
    shooter,
    target,
    { targetId: "target", weaponClass: "assault_rifle", claimedDistanceMeters: 50 },
    100,
    TICK_RATE
  );

  assert.equal(result.accepted, true);
  if (result.accepted) {
    assert.ok(result.damageDealt > 0);
    assert.equal(result.updatedTarget.health, 100 - result.damageDealt);
  }
});

test("rejects a shot against an already-eliminated target", () => {
  const shooter = makePlayer({ userId: "shooter" });
  const target = makePlayer({ userId: "target", eliminated: true, health: 0 });

  const result = handleWeaponFire(
    shooter,
    target,
    { targetId: "target", weaponClass: "assault_rifle", claimedDistanceMeters: 10 },
    100,
    TICK_RATE
  );

  assert.equal(result.accepted, false);
});

test("rejects an implausible shot (distance mismatch) and applies no damage", () => {
  const shooter = makePlayer({ userId: "shooter" });
  const target = makePlayer({ userId: "target", position: { x: 100, y: 0, z: 0 }, health: 100 });

  const result = handleWeaponFire(
    shooter,
    target,
    { targetId: "target", weaponClass: "assault_rifle", claimedDistanceMeters: 5 }, // way off from actual 100m
    100,
    TICK_RATE
  );

  assert.equal(result.accepted, false);
});

test("lethal damage marks the target eliminated", () => {
  const shooter = makePlayer({ userId: "shooter" });
  const target = makePlayer({ userId: "target", position: { x: 5, y: 0, z: 0 }, health: 10 });

  const result = handleWeaponFire(
    shooter,
    target,
    { targetId: "target", weaponClass: "shotgun", claimedDistanceMeters: 5 },
    100,
    TICK_RATE
  );

  assert.equal(result.accepted, true);
  if (result.accepted) {
    assert.equal(result.targetEliminated, true);
    assert.equal(result.updatedTarget.health, 0, "health should clamp at 0, not go negative");
  }
});

test("updates the shooter's last-fire-tick for the weapon used", () => {
  const shooter = makePlayer({ userId: "shooter" });
  const target = makePlayer({ userId: "target", position: { x: 10, y: 0, z: 0 } });

  const result = handleWeaponFire(
    shooter,
    target,
    { targetId: "target", weaponClass: "sidearm", claimedDistanceMeters: 10 },
    250,
    TICK_RATE
  );

  assert.equal(result.accepted, true);
  if (result.accepted) {
    assert.equal(result.updatedShooter.lastFireTickByWeapon["sidearm"], 250);
  }
});

test("rejects firing the same weapon faster than its fire rate allows", () => {
  const shooter = makePlayer({ userId: "shooter", lastFireTickByWeapon: { sidearm: 100 } });
  const target = makePlayer({ userId: "target", position: { x: 10, y: 0, z: 0 } });

  // Sidearm fires 5/s => needs ~2 ticks minimum at 10 ticks/sec; only 1 tick has passed.
  const result = handleWeaponFire(
    shooter,
    target,
    { targetId: "target", weaponClass: "sidearm", claimedDistanceMeters: 10 },
    101,
    TICK_RATE
  );

  assert.equal(result.accepted, false);
});

test("does not mutate the original shooter/target objects", () => {
  const shooter = makePlayer({ userId: "shooter" });
  const target = makePlayer({ userId: "target", position: { x: 10, y: 0, z: 0 }, health: 100 });
  const originalTargetHealth = target.health;

  handleWeaponFire(
    shooter,
    target,
    { targetId: "target", weaponClass: "assault_rifle", claimedDistanceMeters: 10 },
    100,
    TICK_RATE
  );

  assert.equal(target.health, originalTargetHealth, "handleWeaponFire must not mutate the passed-in target");
});
