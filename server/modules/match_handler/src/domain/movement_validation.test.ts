import { test } from "node:test";
import assert from "node:assert/strict";
import { validateMovement, type Vector3 } from "./movement_validation";

const ORIGIN: Vector3 = { x: 0, y: 0, z: 0 };
const MAX_SPEED = 6; // meters/second, a plausible sprint speed

test("accepts movement within max speed", () => {
  // 1 second at 5 m/s along X — under the 6 m/s cap.
  const result = validateMovement(ORIGIN, { x: 5, y: 0, z: 0 }, 1.0, MAX_SPEED);
  assert.equal(result.accepted, true);
  assert.equal(result.wasCorrected, false);
  assert.deepEqual(result.resultingPosition, { x: 5, y: 0, z: 0 });
});

test("accepts movement comfortably within the tolerance boundary", () => {
  // 6 m/s * 1s * 1.15 tolerance = 6.9m allowed; 6.85m is safely under
  // that without relying on exact floating-point boundary equality.
  const result = validateMovement(ORIGIN, { x: 6.85, y: 0, z: 0 }, 1.0, MAX_SPEED);
  assert.equal(result.accepted, true);
});

test("rejects and clamps movement far exceeding max speed", () => {
  // Claims to have moved 100m in 1 second — a blatant speed hack.
  const result = validateMovement(ORIGIN, { x: 100, y: 0, z: 0 }, 1.0, MAX_SPEED);
  assert.equal(result.accepted, false);
  assert.equal(result.wasCorrected, true);
  // Clamped position should be much closer to origin than the claim.
  assert.ok(result.resultingPosition.x < 10);
  assert.ok(result.resultingPosition.x > 0);
});

test("clamped position preserves direction of travel", () => {
  const result = validateMovement(ORIGIN, { x: 0, y: 0, z: -200 }, 1.0, MAX_SPEED);
  assert.equal(result.resultingPosition.x, 0);
  assert.equal(result.resultingPosition.y, 0);
  assert.ok(result.resultingPosition.z < 0, "direction should be preserved (negative Z)");
});

test("rejects non-positive delta time without moving the player", () => {
  const result = validateMovement(ORIGIN, { x: 5, y: 0, z: 0 }, 0, MAX_SPEED);
  assert.equal(result.accepted, false);
  assert.deepEqual(result.resultingPosition, ORIGIN);
});

test("rejects negative delta time (out-of-order message)", () => {
  const result = validateMovement(ORIGIN, { x: 5, y: 0, z: 0 }, -0.5, MAX_SPEED);
  assert.equal(result.accepted, false);
  assert.deepEqual(result.resultingPosition, ORIGIN);
});

test("zero movement over zero-ish tiny delta is still accepted", () => {
  const result = validateMovement(ORIGIN, ORIGIN, 0.016, MAX_SPEED);
  assert.equal(result.accepted, true);
});

test("diagonal movement uses true 3D distance, not axis-summed distance", () => {
  // 3-4-5 triangle-ish in 3D: sqrt(3^2+4^2) = 5m in 1s, under 6 m/s cap.
  const result = validateMovement(ORIGIN, { x: 3, y: 0, z: 4 }, 1.0, MAX_SPEED);
  assert.equal(result.accepted, true);
});
