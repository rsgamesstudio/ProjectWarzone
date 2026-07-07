import { test } from "node:test";
import assert from "node:assert/strict";
import { buildSnapshot } from "./build_snapshot";
import type { WarzoneMatchState } from "../domain/match_state";

function makeState(overrides: Partial<WarzoneMatchState> = {}): WarzoneMatchState {
  return {
    players: {
      "user-1": {
        userId: "user-1",
        username: "RS_GAMER",
        position: { x: 1, y: 0, z: 2 },
        connected: true,
        lastUpdateTick: 0,
        health: 100,
        eliminated: false,
        lastFireTickByWeapon: {},
      },
      "user-2": {
        userId: "user-2",
        username: "Disconnected_Player",
        position: { x: 5, y: 0, z: 5 },
        connected: false,
        lastUpdateTick: 0,
        health: 100,
        eliminated: false,
        lastFireTickByWeapon: {},
      },
    },
    zoneSeed: 42,
    matchStartTick: 0,
    tickRate: 10,
    ...overrides,
  };
}

test("includes only connected players in the snapshot", () => {
  const snapshot = buildSnapshot(makeState(), 20);
  assert.equal(snapshot.players.length, 1);
  assert.equal(snapshot.players[0].userId, "user-1");
});

test("computes elapsed seconds correctly from tick and tick rate", () => {
  const state = makeState({ matchStartTick: 0, tickRate: 10 });
  const snapshot = buildSnapshot(state, 50); // 50 ticks / 10 tick-rate = 5s
  assert.equal(snapshot.elapsedSeconds, 5);
});

test("snapshot includes zone state consistent with elapsed time", () => {
  const snapshot = buildSnapshot(makeState(), 0);
  assert.ok(snapshot.zone.radiusMeters > 0);
  assert.ok(snapshot.zone.nextShrinkAtSeconds !== undefined);
});

test("player position in snapshot matches state exactly", () => {
  const snapshot = buildSnapshot(makeState(), 0);
  assert.deepEqual(snapshot.players[0].position, { x: 1, y: 0, z: 2 });
});
