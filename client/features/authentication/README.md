# Authentication

**Layer:** Client feature module
**Status:** Implemented (Phase 4 services + Phase 6 UI wiring) — Guest
login fully functional on all platforms; Google/Email login functional
on HTML5/Web exports only (see
infrastructure/firebase_web_identity_provider.gd scope note). Native
Android/iOS Google/Email login requires a follow-up native plugin,
tracked as explicit future work, not silently assumed done.

## Presentation (added Phase 6)

`presentation/login_screen.gd`/`.tscn` — the first real UI wiring of
`AuthService` (previously built but unconnected). Sits between the
loading screen and the lobby in `UIRoot`'s flow. Button mapping:

- **"Sign in with RS GAMES STUDIO"** → reveals an email/password form
  → `AuthService.login_with_email_async()`. This is our existing Email
  login, presented under the studio's own brand — no new backend, just
  a UI framing choice.
- **"Sign in with Google"** → `AuthService.login_with_google_async()` (HTML5 only today)
- **"Sign in with Facebook"** → NOT in this project's original auth
  scope (Guest/Google/Email only). Shown for layout completeness,
  wired to a "not implemented" message rather than faked as working.
- **"Continue as Guest"** → `AuthService.login_as_guest_async()`, fully functional everywhere

Also starts the lobby theme music (looped) via `Services.resolve("MusicPlayer")` — see `client/core/audio/README.md`.

## Responsibility

Handles Guest/Google/Email login flows and nickname claiming. Holds
the client-side session (`AuthSession`) once logged in. Delegates
identity verification to Firebase (Google/Email) or a locally
generated device ID (Guest), and session issuance to Nakama via
`client/networking/nakama_client`.

## Structure

- `domain/auth_session.gd` — pure session value object
- `domain/nickname_rules.gd` — client-side format pre-check (UX only; server is authoritative, see ADR-0002)
- `application/auth_service.gd` — orchestrates login flows + nickname claiming
- `infrastructure/guest_identity_provider.gd` — stable local device ID, works everywhere
- `infrastructure/firebase_web_identity_provider.gd` — Firebase Web SDK bridge via JavaScriptBridge, HTML5-only
- `infrastructure/web/firebase_auth_shim.js` — the actual Firebase Web SDK calls

## Depends On

- `client/networking/nakama_client` (NakamaClientAdapter)
- `client/core/di` (Services, to resolve NakamaClientAdapter)

## Public Interface

- `AuthService.login_as_guest_async() -> AuthSession`
- `AuthService.login_with_google_async() -> AuthSession`
- `AuthService.login_with_email_async(email, password, create_if_missing) -> AuthSession`
- `AuthService.claim_nickname_async(nickname) -> Dictionary`
- `AuthService.current_session` (readonly)

## Tests

- `client/tests/unit/features/authentication/test_nickname_rules.gd` (8 cases)
- `client/tests/unit/features/authentication/test_auth_session.gd` (5 cases)
- `client/tests/unit/features/authentication/test_auth_service.gd` (9 cases, using fakes under `fixtures/` for every infrastructure dependency — no real network/browser)
- `login_screen.gd` itself is not unit tested (presentation-layer, scene-tree dependent) — reviewed structurally but not executed; see PHASE_06 report

## Notes

`AuthService` is not yet wired into a UI screen or Bootstrap — that
composition happens once Phase 9 (UI System) gives it somewhere to be
constructed from. For now it's fully testable and ready to be
resolved from `Services` (once something registers it) or constructed
directly with its three dependencies.

Nickname claiming UI lives here but validation is server-side only
(see ADR-0002); `nickname_rules.gd` exists purely to disable a "Claim"
button / show inline errors before a round trip, not as a source of
truth.
