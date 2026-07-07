import { test } from "node:test";
import assert from "node:assert/strict";
import "./index"; // runs InitModule assignment onto globalThis as a side effect

test("InitModule registers the match handler under the correct name with all 7 functions", () => {
  const registeredMatches: { name: string; handler: any }[] = [];
  const registeredRpcs: { id: string; func: any }[] = [];

  const fakeInitializer = {
    registerMatch: (name: string, handler: any) => {
      registeredMatches.push({ name, handler });
    },
    registerRpc: (id: string, func: any) => {
      registeredRpcs.push({ id, func });
    },
  };

  const fakeLogger = { info: () => "", warn: () => "" };

  const initModule = (globalThis as unknown as { InitModule: Function }).InitModule;
  initModule({}, fakeLogger, {}, fakeInitializer);

  assert.equal(registeredMatches.length, 1);
  assert.equal(registeredMatches[0].name, "meridian_battle_royale");

  const handler = registeredMatches[0].handler;
  for (const fn of ["matchInit", "matchJoinAttempt", "matchJoin", "matchLeave", "matchLoop", "matchTerminate", "matchSignal"]) {
    assert.equal(typeof handler[fn], "function", `expected handler.${fn} to be a function`);
  }

  assert.equal(registeredRpcs.length, 1);
  assert.equal(registeredRpcs[0].id, "create_match_for_testing");
});

test("create_match_for_testing RPC calls nk.matchCreate and returns its matchId as JSON", () => {
  let capturedInitializer: any;
  const fakeInitializer = {
    registerMatch: () => {},
    registerRpc: (_id: string, func: any) => {
      capturedInitializer = func;
    },
  };
  const fakeLogger = { info: () => "", warn: () => "" };

  const initModule = (globalThis as unknown as { InitModule: Function }).InitModule;
  initModule({}, fakeLogger, {}, fakeInitializer);

  const fakeNk = {
    matchCreate: (_module: string, _params: unknown) => "fake-match-id-123",
  };

  const response = capturedInitializer({}, fakeLogger, fakeNk, "");
  const parsed = JSON.parse(response);
  assert.equal(parsed.matchId, "fake-match-id-123");
});
