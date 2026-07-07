import { test } from "node:test";
import assert from "node:assert/strict";
import { handlePlayerInput } from "./handle_player_input";
import type { PlayerMatchState } from "../domain/match_state";

function makePlayer(overrides: Partial<PlayerMatchState> = {}): PlayerMatchState {
  return {
    userId: "user-1",
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

test("accepts legitimate movement and updates position/tick", () => {
  const player = makePlayer();
  const result = handlePlayerInput(player, { position: { x: 1, y: 0, z: 0 }, deltaSeconds: 0.5 }, 10);

  assert.equal(result.correction, null);
  assert.deepEqual(result.updatedPlayer.position, { x: 1, y: 0, z: 0 });
  assert.equal(result.updatedPlayer.lastUpdateTick, 10);
});

test("corrects and flags an implausible speed-hack style input", () => {
  const player = makePlayer();
  const result = handlePlayerInput(player, { position: { x: 500, y: 0, z: 0 }, deltaSeconds: 0.1 }, 10);

  assert.notEqual(result.correction, null);
  assert.ok(result.updatedPlayer.position.x < 500);
});

test("does not mutate the original player object", () => {
  const player = makePlayer();
  const originalPosition = { ...player.position };
  handlePlayerInput(player, { position: { x: 999, y: 0, z: 0 }, deltaSeconds: 0.1 }, 10);

  assert.deepEqual(player.position, originalPosition, "input handling must not mutate the passed-in player state");
});

test("preserves other player fields (username, connected) unchanged", () => {
  const player = makePlayer({ username: "SomeoneElse" });
  const result = handlePlayerInput(player, { position: { x: 1, y: 0, z: 0 }, deltaSeconds: 0.5 }, 5);

  assert.equal(result.updatedPlayer.username, "SomeoneElse");
  assert.equal(result.updatedPlayer.connected, true);
});
