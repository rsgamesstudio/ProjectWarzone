import { verifyFirebaseIdToken, InvalidFirebaseTokenError } from "../infrastructure/firebase_token_verifier";

export type VerifyGoogleLoginResult =
  | { success: true; firebaseUid: string }
  | { success: false; message: string };

/**
 * Verifies the Firebase ID token a client obtained via Google Sign-In
 * before Nakama is allowed to proceed with `authenticateCustom`. The
 * Firebase UID becomes Nakama's `custom_id` — this is what makes a
 * given Google account always map to the same Nakama account.
 *
 * `firebaseProjectId` is read from the module's environment
 * configuration (see `local.yml` / production runtime.env) rather
 * than hardcoded, so staging/production can use different Firebase
 * projects without a code change.
 */
export function verifyGoogleLogin(
  nk: nkruntime.Nakama,
  idToken: string,
  firebaseProjectId: string
): VerifyGoogleLoginResult {
  if (!firebaseProjectId) {
    return {
      success: false,
      message: "Server misconfiguration: FIREBASE_PROJECT_ID is not set.",
    };
  }

  try {
    const identity = verifyFirebaseIdToken(nk, idToken, firebaseProjectId);
    return { success: true, firebaseUid: identity.firebaseUid };
  } catch (err) {
    if (err instanceof InvalidFirebaseTokenError) {
      return { success: false, message: err.message };
    }
    throw err;
  }
}
