import { matchHandler, MATCH_MODULE_NAME } from "./infrastructure/match_handler";

/**
 * Module entry point. Registers:
 *
 *   - the `meridian_battle_royale` match handler
 *   - RPC `create_match_for_testing` — a TEMPORARY manual QA entry
 *     point that directly calls nk.matchCreate. Real match creation
 *     will go through the matchmaker in Phase 11, which assigns
 *     players to matches automatically rather than requiring a client
 *     to explicitly request one by name. This RPC exists purely so
 *     Phase 5 can be manually tested end-to-end before Phase 11
 *     exists — see the phase report's testing checklist.
 */
const InitModule: nkruntime.InitModule = function (
  _ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer
): void {
  initializer.registerMatch(MATCH_MODULE_NAME, matchHandler);

  initializer.registerRpc("create_match_for_testing", (_ctx, _logger, nk) => {
    const matchId = nk.matchCreate(MATCH_MODULE_NAME, {});
    return JSON.stringify({ matchId });
  });

  logger.info("Project Warzone match handler module initialized.");
};

// See server/modules/authentication/src/index.ts for why this
// explicit global assignment (rather than an ES `export`) is required
// for Nakama's runtime loader to find InitModule.
(globalThis as unknown as { InitModule: nkruntime.InitModule }).InitModule = InitModule;
