# UI System (Shared)

**Layer:** Client feature module
**Status:** Partially implemented — early prototype (built ahead of
its Phase 9 schedule, at explicit request; see
`docs/phases/PHASE_04_AUTHENTICATION.md` addendum). `UIRoot`, splash
screen, and loading screen exist and work; the full shared widget/
theme library and generic navigation stack described below remain
Phase 9 work.

## Responsibility

Shared UI framework: theme, reusable widgets, HUD composition root,
menu navigation stack.

## What Exists Today

- `presentation/ui_root.gd` / `ui_root.tscn` — the project's actual
  `run/main_scene`. Currently a linear splash → loading → login →
  lobby sequence (login screen added Phase 6, see
  `client/features/authentication/presentation/login_screen.gd`), not
  yet a general push/pop navigation stack (see that file's docstring
  for why).
- `presentation/splash_screen/` — studio logo intro using the real
  RS GAMES crest (`client/assets/textures/branding/rs_games_logo.png`)
- `presentation/loading_screen/` — progress bar + rotating tips.
  Progress is SIMULATED (documented in `loading_screen.gd`) — no real
  asset-streaming system exists yet (that's Phase 13).
- `domain/loading_tips_provider.gd` — pure, tested tip-rotation logic

## Depends On

- `client/core/events`
- `client/core/di`

## Public Interface

Today: none formally exposed as a service yet — `UIRoot` is the main
scene itself, not something other code resolves via `Services`.

Planned (Phase 9, once this becomes a general shell rather than one
hardcoded sequence):
- `UIRoot.push_screen(scene)`
- `UIRoot.show_hud_element(id, visible)`

## Tests

- `client/tests/unit/features/ui/test_loading_tips_provider.gd` (5 cases)

## Notes

Feature-specific UI (inventory grid, mission list, etc.) lives in its
owning feature folder and composes into this shared shell once that
shell is generalized in Phase 9.

**Content note:** the wordmark treatment in the loading screen is an
original typography treatment (plain white/gold split text), not a
copy of any existing game's logo trade dress — see ADR-0005 for the
full reasoning behind every naming/visual choice made in this
prototype.
