import { provisionAccountIfNeeded } from "./application/provision_account";
import { claimNicknameUseCase } from "./application/claim_nickname";
import { verifyGoogleLogin } from "./application/verify_google_login";

/**
 * `ctx.userId` is typed as optional in the ambient Context type
 * because some hook contexts (e.g. server startup) have no
 * authenticated user. Every hook registered below only ever runs in
 * an authenticated context, so a missing userId here indicates a
 * genuine Nakama runtime contract violation, not a normal case to
 * silently work around.
 */
function requireUserId(ctx: nkruntime.Context): string {
  if (!ctx.userId) {
    throw new Error("Expected an authenticated userId in this hook context.");
  }
  return ctx.userId;
}

/**
 * Module entry point. Registered hooks/RPCs:
 *
 *   - after authenticateDevice / authenticateEmail / authenticateCustom:
 *     provision (or confirm) the warzone_accounts + placeholder
 *     nickname rows for the logged-in user (see ADR-0004).
 *   - before authenticateCustom: verify the supplied Firebase ID
 *     token and rewrite the custom_id to the verified Firebase UID,
 *     so a client can never simply claim an arbitrary custom_id.
 *   - RPC `claim_nickname`: the one genuinely custom login-adjacent
 *     operation (see ADR-0002).
 *
 * Types referenced here (nkruntime.*) come from the ambient global
 * namespace declared in ../types/nakama-runtime.d.ts — see that
 * folder's VENDORED.md for why this is not a normal `import`.
 */
const InitModule: nkruntime.InitModule = function (
  _ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer
): void {
  initializer.registerAfterAuthenticateDevice((ctx, _logger, nk, _data, _request) => {
    provisionAccountIfNeeded(nk, requireUserId(ctx));
  });

  initializer.registerAfterAuthenticateEmail((ctx, _logger, nk, _data, _request) => {
    provisionAccountIfNeeded(nk, requireUserId(ctx));
  });

  initializer.registerAfterAuthenticateCustom((ctx, _logger, nk, _data, _request) => {
    provisionAccountIfNeeded(nk, requireUserId(ctx));
  });

  initializer.registerBeforeAuthenticateCustom((ctx, logger, nk, request) => {
    const firebaseIdToken = request.account?.id;
    if (!firebaseIdToken) {
      throw new Error("Missing Firebase ID token in authenticateCustom request.");
    }

    const firebaseProjectId = ctx.env["FIREBASE_PROJECT_ID"] ?? "";
    const result = verifyGoogleLogin(nk, firebaseIdToken, firebaseProjectId);

    if (!result.success) {
      logger.warn("Google login rejected: %s", result.message);
      throw new Error(result.message);
    }

    // Rewrite the incoming custom_id to the *verified* Firebase UID,
    // not whatever the client originally sent as `account.id`. This
    // is the step that actually prevents a client from authenticating
    // as an arbitrary custom_id of its choosing.
    request.account = { ...request.account, id: result.firebaseUid };
    return request;
  });

  initializer.registerRpc("claim_nickname", (ctx, _logger, nk, payload) => {
    let parsed: { nickname?: string };
    try {
      parsed = JSON.parse(payload);
    } catch {
      throw new Error("claim_nickname: payload must be JSON with a 'nickname' field.");
    }

    if (!parsed.nickname || typeof parsed.nickname !== "string") {
      throw new Error("claim_nickname: 'nickname' field is required and must be a string.");
    }

    const result = claimNicknameUseCase(nk, requireUserId(ctx), parsed.nickname);
    return JSON.stringify(result);
  });

  logger.info("Project Warzone authentication module initialized.");
};

// Nakama's runtime loads the compiled bundle as a plain script and
// looks up a GLOBAL function named `InitModule` — it does not
// `require()` this file as a CommonJS module. Because this file uses
// ES `import` statements, TypeScript treats it as a module, which
// would otherwise keep `InitModule` scoped to this file rather than
// attaching it to the global object. This explicit assignment is
// what makes Nakama able to find it at runtime.
(globalThis as unknown as { InitModule: nkruntime.InitModule }).InitModule = InitModule;
