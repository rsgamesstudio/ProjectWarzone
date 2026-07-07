# ADR-0004: Authentication Strategy — Native Nakama Auth + Hooks

**Status:** Accepted
**Date:** 2026-07-04

## Context

The brief requires Guest, Google, and Email login, plus the permanent
UID/nickname system from ADR-0002. Nakama already provides
production-hardened primitives for exactly this — the question is
whether to use them or build custom RPCs from scratch.

## Decision

Use Nakama's **built-in authentication methods** rather than custom
login RPCs:

- **Guest** → `authenticateDevice` (client-generated stable device ID)
- **Email** → `authenticateEmail` (Nakama's own salted-hash email/password storage)
- **Google** → `authenticateCustom`, with a `custom_id` equal to the
  user's **Firebase UID**. Firebase handles the actual Google OAuth
  flow client-side; our server verifies the resulting Firebase ID
  token server-side (see `infrastructure/firebase_token_verifier.ts`)
  **before** allowing the custom authentication to succeed, using
  Nakama's `RegisterBeforeAuthenticateCustom` hook.

Account provisioning (creating the `warzone_accounts` row and a
placeholder nickname) happens in `RegisterAfterAuthenticateDevice` /
`AfterAuthenticateEmail` / `AfterAuthenticateCustom` hooks — idempotent
on every login, not just the first.

Nickname claiming is the one genuinely custom piece: an RPC
(`claim_nickname`) validated against ADR-0002's rules.

## Alternatives Considered

- **Fully custom RPCs for every login method** (`authenticate_guest`,
  `authenticate_google`, etc.): would duplicate session issuance,
  token expiry, and refresh-token handling that Nakama's built-in
  methods already implement and battle-test. Rejected as needless
  reinvention.
- **Verifying the Firebase ID token via local RS256 signature
  verification** against Google's rotating public keys: the Nakama JS
  runtime's sandboxed environment makes this notably harder to do
  safely than in a normal Node.js process. We instead call Google's
  `tokeninfo` HTTP endpoint via `nk.httpRequest` (see
  `firebase_token_verifier.ts` for the full tradeoff writeup). This is
  explicitly flagged as revisitable via a Go runtime module if login
  volume ever makes the HTTP round trip a bottleneck.

## Consequences

- Client-side, "login" means: sign in with Firebase (Google/Email) or
  generate a stable device ID (Guest) — see
  `client/features/authentication/` — then hand the resulting
  credential to Nakama's client SDK `authenticateX()` methods
  directly. There is no custom "login" RPC to call.
- Server-side, `FIREBASE_PROJECT_ID` must be set in the Nakama runtime
  environment config (`local.yml` locally; a real secret store in
  production) or Google login is rejected with a clear
  misconfiguration error rather than silently failing.
- Nickname claiming remains the one place with genuinely custom
  business logic, keeping the module's surface area small and easy to
  reason about.
