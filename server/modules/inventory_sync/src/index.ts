import { provisionStarterItemsIfNeeded } from "./application/provision_starter_items";
import { getInventory } from "./application/get_inventory";
import { equipInventoryItem } from "./application/equip_item";
import { purchaseItem } from "./application/purchase_item";
import { findAccountIdByNakamaUserId } from "./infrastructure/warzone_inventory_db";

/**
 * Module entry point. Registers:
 *
 *   - after authenticateDevice/Email/Custom: grants + equips default
 *     starter items (idempotent). NOTE: this module registers its OWN
 *     copy of these after-hooks, independent of
 *     `server/modules/authentication`'s — this assumes Nakama calls
 *     every registered after-hook for a given event across all loaded
 *     modules (not just the first one registered), which is the
 *     standard multi-module Nakama pattern. This could not be
 *     verified against a running Nakama instance in the development
 *     sandbox this was written in — confirm both modules' hooks
 *     actually fire on login before relying on this in production;
 *     see the phase report's testing checklist.
 *   - RPC `get_inventory`: returns the caller's full inventory view
 *   - RPC `equip_item`: equips an owned item into its (derived) slot
 *   - RPC `purchase_item`: spends Marks to buy a catalog item
 */
function requireUserId(ctx: nkruntime.Context): string {
  if (!ctx.userId) {
    throw new Error("Expected an authenticated userId in this hook/RPC context.");
  }
  return ctx.userId;
}

function requireAccountId(nk: nkruntime.Nakama, ctx: nkruntime.Context): string {
  const accountId = findAccountIdByNakamaUserId(nk, requireUserId(ctx));
  if (!accountId) {
    throw new Error("No warzone_accounts row exists for this user yet — authenticate first.");
  }
  return accountId;
}

const InitModule: nkruntime.InitModule = function (
  _ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer
): void {
  initializer.registerAfterAuthenticateDevice((ctx, _logger, nk) => {
    provisionStarterItemsIfNeeded(nk, requireUserId(ctx));
  });
  initializer.registerAfterAuthenticateEmail((ctx, _logger, nk) => {
    provisionStarterItemsIfNeeded(nk, requireUserId(ctx));
  });
  initializer.registerAfterAuthenticateCustom((ctx, _logger, nk) => {
    provisionStarterItemsIfNeeded(nk, requireUserId(ctx));
  });

  initializer.registerRpc("get_inventory", (ctx, _logger, nk) => {
    const accountId = requireAccountId(nk, ctx);
    return JSON.stringify(getInventory(nk, accountId));
  });

  initializer.registerRpc("equip_item", (ctx, _logger, nk, payload) => {
    const accountId = requireAccountId(nk, ctx);
    let parsed: { itemId?: string };
    try {
      parsed = JSON.parse(payload);
    } catch {
      throw new Error("equip_item: payload must be JSON with an 'itemId' field.");
    }
    if (!parsed.itemId || typeof parsed.itemId !== "string") {
      throw new Error("equip_item: 'itemId' field is required and must be a string.");
    }
    return JSON.stringify(equipInventoryItem(nk, accountId, parsed.itemId));
  });

  initializer.registerRpc("purchase_item", (ctx, _logger, nk, payload) => {
    const accountId = requireAccountId(nk, ctx);
    let parsed: { itemId?: string };
    try {
      parsed = JSON.parse(payload);
    } catch {
      throw new Error("purchase_item: payload must be JSON with an 'itemId' field.");
    }
    if (!parsed.itemId || typeof parsed.itemId !== "string") {
      throw new Error("purchase_item: 'itemId' field is required and must be a string.");
    }
    return JSON.stringify(purchaseItem(nk, accountId, parsed.itemId));
  });

  logger.info("Project Warzone inventory sync module initialized.");
};

// See server/modules/authentication/src/index.ts for why this
// explicit global assignment (rather than an ES `export`) is required
// for Nakama's runtime loader to find InitModule.
(globalThis as unknown as { InitModule: nkruntime.InitModule }).InitModule = InitModule;
