
/**
 * Verifies a Firebase ID token by calling Google's public tokeninfo
 * endpoint over HTTP, rather than performing local RS256 signature
 * verification. This is a deliberate, documented tradeoff:
 *
 *   - The Nakama JS runtime (a sandboxed goja VM) does not expose a
 *     crypto library capable of RS256 JWT verification against
 *     Google's rotating public keys without pulling in a large
 *     dependency graph of uncertain goja-compatibility.
 *   - Google's `tokeninfo` endpoint is documented and rate-limited
 *     but perfectly adequate for our current auth volume.
 *   - If/when login volume makes the per-request HTTP round trip a
 *     bottleneck, the fix is to move this specific verification into
 *     a Go-based Nakama runtime module (Go has first-class JWT/crypto
 *     support) — the call signature below is written so that swap
 *     would only touch this one file, not its callers.
 *
 * See docs/adr/ADR-0004 for the full authentication strategy this
 * fits into.
 */

const TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo";

export interface VerifiedFirebaseIdentity {
  firebaseUid: string;
  email: string | null;
  emailVerified: boolean;
}

export class InvalidFirebaseTokenError extends Error {
  constructor(reason: string) {
    super(`Invalid Firebase ID token: ${reason}`);
    this.name = "InvalidFirebaseTokenError";
  }
}

/**
 * @param expectedProjectId The Firebase project ID (matches the
 *   token's `aud` claim). Passed explicitly rather than read from a
 *   module-level constant so tests can supply a fake value.
 */
export function verifyFirebaseIdToken(
  nk: nkruntime.Nakama,
  idToken: string,
  expectedProjectId: string
): VerifiedFirebaseIdentity {
  const response = nk.httpRequest(
    `${TOKENINFO_URL}?id_token=${encodeURIComponent(idToken)}`,
    "get",
    {},
    undefined,
    5000
  );

  if (response.code !== 200) {
    throw new InvalidFirebaseTokenError(
      `tokeninfo endpoint returned HTTP ${response.code}`
    );
  }

  let payload: Record<string, unknown>;
  try {
    payload = JSON.parse(response.body);
  } catch {
    throw new InvalidFirebaseTokenError("tokeninfo response was not valid JSON");
  }

  const audience = payload["aud"];
  if (audience !== expectedProjectId) {
    throw new InvalidFirebaseTokenError(
      `audience mismatch: expected "${expectedProjectId}", got "${String(audience)}"`
    );
  }

  const issuer = payload["iss"];
  const expectedIssuer = `https://securetoken.google.com/${expectedProjectId}`;
  if (issuer !== expectedIssuer) {
    throw new InvalidFirebaseTokenError(
      `issuer mismatch: expected "${expectedIssuer}", got "${String(issuer)}"`
    );
  }

  const sub = payload["sub"];
  if (typeof sub !== "string" || sub.length === 0) {
    throw new InvalidFirebaseTokenError("missing 'sub' claim (Firebase UID)");
  }

  const exp = payload["exp"];
  const nowSeconds = Math.floor(Date.now() / 1000);
  if (typeof exp !== "string" && typeof exp !== "number") {
    throw new InvalidFirebaseTokenError("missing 'exp' claim");
  }
  if (Number(exp) < nowSeconds) {
    throw new InvalidFirebaseTokenError("token has expired");
  }

  return {
    firebaseUid: sub,
    email: typeof payload["email"] === "string" ? (payload["email"] as string) : null,
    emailVerified: payload["email_verified"] === "true" || payload["email_verified"] === true,
  };
}
