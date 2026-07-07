# Authentication Module

**Layer:** Nakama server module
**Status:** Implemented (Phase 4)

## Responsibility

Provisions `warzone_accounts`/`warzone_nicknames` rows on login,
verifies Firebase ID tokens for Google sign-in before allowing Nakama's
`authenticateCustom` to succeed, and handles nickname claims — see
ADR-0002, ADR-0003, and ADR-0004 for the full design rationale.

Uses Nakama's own built-in `authenticateDevice`/`authenticateEmail`/
`authenticateCustom` rather than custom login RPCs (ADR-0004) — this
module's job is hooking into those, not reimplementing them.

## Structure

- `domain/nickname_policy.ts` — pure format validation + placeholder generation (no I/O)
- `infrastructure/warzone_db.ts` — `warzone_*` table access via `nk.sqlQuery`/`sqlExec`
- `infrastructure/firebase_token_verifier.ts` — Firebase ID token verification via Google's tokeninfo endpoint
- `application/provision_account.ts` — idempotent account/nickname provisioning
- `application/claim_nickname.ts` — the nickname claim use case
- `application/verify_google_login.ts` — Firebase verification orchestration for the before-hook
- `index.ts` — registers hooks/RPC, attaches `InitModule` to the global scope (see that file's docstring for why)
- `types/nakama-runtime.d.ts` — vendored ambient Nakama runtime types (see `types/VENDORED.md`)

## Depends On

- PostgreSQL (`warzone_accounts`, `warzone_nicknames` — same database Nakama itself uses, per ADR-0003)
- `FIREBASE_PROJECT_ID` runtime environment variable (Google login only; Guest/Email work without it)

## Public Interface

- Hooks: `registerAfterAuthenticateDevice`, `registerAfterAuthenticateEmail`, `registerAfterAuthenticateCustom`, `registerBeforeAuthenticateCustom`
- RPC `claim_nickname` — payload `{"nickname": string}`, returns `{"success": true, "nickname": string}` or `{"success": false, "errorCode": "INVALID_FORMAT"|"ALREADY_TAKEN", "message": string}`

## Tests

- `npm test` (Node's built-in test runner via `tsx`): 13 tests —
  9 for `nickname_policy.ts` format rules, 4 for `claim_nickname.ts`
  orchestration against an in-memory fake of the SQL functions
- `npm run typecheck` — `tsc --noEmit`, verified clean against the real
  vendored Nakama runtime types
- `npm run build` — bundles via esbuild; verified the output actually
  attaches a global `InitModule` the way Nakama's loader expects

## Notes

Nickname uniqueness enforced via the database's case-insensitive
unique index (migration 0001) + a `UNIQUE(account_id)` constraint
(migration 0002) — not application-layer check-then-write, which would
race under concurrent requests.
