# Lobby

**Layer:** Client feature module
**Status:** Partially implemented — early UI prototype with mock data
(built ahead of its Phase 11 schedule, at explicit request; expanded
further in Phase 6 to match a richer reference layout). Real party
formation, ready-check, and live mode/map/economy data remain Phase 8/
9/11 work.

## Responsibility

Pre-match social space: player status, currencies, promotions, event
banners, mode/map display, chat entry point, party formation.

## What Exists Today

- `presentation/lobby_screen.gd` / `.tscn` — renders player info, VIP
  tier, currencies, a promo banner, Season Path progress, a Founders
  Cup event banner, world chat, and mode-select cards from a
  `LobbyViewModel`
- `presentation/mode_card.gd` / `.tscn` — a single selectable mode/map card
- `domain/lobby_view_model.gd`, `domain/lobby_mode_entry.gd` — pure
  data the screen renders
- `infrastructure/mock_lobby_data_provider.gd` — **TEMPORARY**
  fabricated data source; see that file's docstring for exactly which
  real service replaces it, and when (Phases 4/8/9/11)

Buttons without a real feature behind them yet (Start, Loadout, Clan,
Leaderboard, Store, Fortune Cache, Character, Missions, Events,
Friends) log which future phase implements them rather than silently
doing nothing or faking success — see `lobby_screen.gd`.

## Original Naming

This feature's content is entirely original — see **ADR-0005** and its
Phase 6 addendum for the full reasoning: map "Meridian", modes "Battle
Royale"/"Skirmish", currencies "Credits"/"Marks", plus "Fortune Cache"
(gacha-style feature), "Nightfall Bundle" (promo), "Founders Cup"
(event), and "Season Path" (progression track) — each replacing a
trademarked or branded name/mechanic from an existing title that
appeared in reference images used for layout inspiration only.
`test_mock_lobby_data_provider.gd` includes a regression guard against
any of those names re-entering the mock data.

## Depends On

- `client/features/matchmaking` (once Phase 11 replaces the mock data)
- `client/features/lobby` itself for party formation (Phase 11)

## Public Interface

Not yet exposed as a resolvable service — the lobby screen is
constructed directly by `UIRoot` today. Will gain a proper
`LobbyService` once Phase 11 gives it real party/matchmaking state to
manage.

## Tests

- `client/tests/unit/features/lobby/test_mock_lobby_data_provider.gd`
  (10 cases) — including the trademark/branded-name regression guard

## Notes

Squad system (2-4 players) is composed here before handing off to
matchmaking, once that composition logic actually exists (Phase 11).

Resumes the lobby theme music (`Services.resolve("MusicPlayer").resume_if_paused()`)
on entry — see `client/core/audio/README.md`. Currently a no-op since
nothing pauses it yet (that's Phase 11's job, once a real match-join
flow exists).
