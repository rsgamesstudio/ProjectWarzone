import { test } from "node:test";
import assert from "node:assert/strict";
import "./index";

test("InitModule registers 3 after-auth hooks and 3 RPCs", () => {
  const registeredHooks: string[] = [];
  const registeredRpcs: { id: string; func: Function }[] = [];

  const fakeInitializer = {
    registerAfterAuthenticateDevice: (_fn: Function) => registeredHooks.push("device"),
    registerAfterAuthenticateEmail: (_fn: Function) => registeredHooks.push("email"),
    registerAfterAuthenticateCustom: (_fn: Function) => registeredHooks.push("custom"),
    registerRpc: (id: string, func: Function) => registeredRpcs.push({ id, func }),
  };
  const fakeLogger = { info: () => "", warn: () => "" };

  const initModule = (globalThis as unknown as { InitModule: Function }).InitModule;
  initModule({}, fakeLogger, {}, fakeInitializer);

  assert.deepEqual(registeredHooks.sort(), ["custom", "device", "email"]);
  assert.deepEqual(
    registeredRpcs.map((r) => r.id).sort(),
    ["equip_item", "get_inventory", "purchase_item"]
  );
});
