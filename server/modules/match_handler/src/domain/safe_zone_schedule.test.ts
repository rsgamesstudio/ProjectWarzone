import { test } from "node:test";
import assert from "node:assert/strict";
import {
  getZoneStateAtElapsedSeconds,
  ZONE_PHASES,
  INITIAL_RADIUS_METERS,
} from "./safe_zone_schedule";

const SEED = 12345;

test("before match start, zone is at full initial radius", () => {
  const state = getZoneStateAtElapsedSeconds(-1, SEED);
  assert.equal(state.radiusMeters, INITIAL_RADIUS_METERS);
  assert.equal(state.phaseIndex, -1);
});

test("at time zero, radius has not shrunk yet", () => {
  const state = getZoneStateAtElapsedSeconds(0, SEED);
  assert.equal(state.radiusMeters, INITIAL_RADIUS_METERS);
  assert.equal(state.phaseIndex, 0);
});

test("radius strictly decreases as elapsed time increases within a phase", () => {
  const early = getZoneStateAtElapsedSeconds(10, SEED);
  const later = getZoneStateAtElapsedSeconds(80, SEED);
  assert.ok(later.radiusMeters < early.radiusMeters, "radius should shrink over time within phase 0");
});

test("radius exactly matches phase target at phase boundary", () => {
  const phase0 = ZONE_PHASES[0];
  const state = getZoneStateAtElapsedSeconds(phase0.endsAtSeconds - 0.001, SEED);
  assert.ok(Math.abs(state.radiusMeters - phase0.radiusMeters) < 0.1);
});

test("after all phases complete, radius stays at the final phase's target", () => {
  const lastPhase = ZONE_PHASES[ZONE_PHASES.length - 1];
  const state = getZoneStateAtElapsedSeconds(lastPhase.endsAtSeconds + 500, SEED);
  assert.equal(state.radiusMeters, lastPhase.radiusMeters);
  assert.equal(state.nextShrinkAtSeconds, null);
  assert.equal(state.phaseIndex, ZONE_PHASES.length - 1);
});

test("same seed and elapsed time always produce the same center (determinism)", () => {
  const a = getZoneStateAtElapsedSeconds(200, SEED);
  const b = getZoneStateAtElapsedSeconds(200, SEED);
  assert.deepEqual(a.center, b.center);
});

test("different seeds produce different centers for the same elapsed time", () => {
  const a = getZoneStateAtElapsedSeconds(200, 111);
  const b = getZoneStateAtElapsedSeconds(200, 222);
  assert.notDeepEqual(a.center, b.center);
});

test("new zone center always stays within the previous zone's bounds", () => {
  // Phase 1's center must be within phase 0's radius of the match
  // center, since a zone that jumps outside the current playable
  // area would strand players outside it instantly.
  const phase0 = ZONE_PHASES[0];
  const state = getZoneStateAtElapsedSeconds(phase0.endsAtSeconds + 1, SEED);
  const distanceFromMatchCenter = Math.sqrt(state.center.x ** 2 + state.center.z ** 2);
  assert.ok(distanceFromMatchCenter <= phase0.radiusMeters);
});

test("nextShrinkAtSeconds reports the correct upcoming boundary", () => {
  const state = getZoneStateAtElapsedSeconds(50, SEED);
  assert.equal(state.nextShrinkAtSeconds, ZONE_PHASES[0].endsAtSeconds);
});
