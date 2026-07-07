# Client Assets

Original or open-license assets only — no assets copied from existing
commercial games (see root `README.md` and `CODING_STANDARDS.md`).

## Provenance Log

Every asset added here should be traceable to either "original,
created by RS GAMES" or a specific open license. As of Phase 7:

| Path | Source | License |
|---|---|---|
| `textures/branding/rs_games_logo.png` | RS GAMES's own studio crest, supplied directly by the studio | Studio-owned original artwork |
| `audio/music/lobby_theme.mp3` ("Iron Echo March") | AI-generated via Suno (artist tag "ravenmusical026"), supplied by the studio | **License TBD** — Suno's commercial usage terms depend on subscription tier; confirm commercial rights before shipping in a released build. Safe to use for internal development/testing in the meantime. |

Photoreal battlefield/character artwork used only as early *layout
reference* (never shipped as an asset) is discussed in
`docs/adr/ADR-0005-original-content-naming.md` — none of it lives in
this folder, by design.

## Folder Structure

- `models/` — Blender-authored 3D assets (Phase 6+)
- `textures/` — textures, including `branding/` for studio/game logos
- `audio/` — open-license audio only
- `animations/` — character/weapon animation data (Phase 6+)
