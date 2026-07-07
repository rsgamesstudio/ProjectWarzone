# Phase 1 — Project Architecture

## Goal

Establish the architectural foundation of Project Warzone before any
gameplay code is written: repository shape, layering rules, dependency
rules, naming/legal boundaries, and the roadmap contract that all
future phases follow.

## Decisions Made This Phase

1. **Feature-based, Clean-Architecture-layered folder structure** for
   both client and server. See `ARCHITECTURE.md` §3–4.
2. **Dependency Injection via a custom `ServiceContainer`**, not raw
   Godot autoload sprawl. See `ARCHITECTURE.md` §5.
3. **Firebase is identity/notifications/analytics only** — Nakama
   remains the sole gameplay authority. See `ARCHITECTURE.md` §2, §7.
4. **Cross-feature communication only via Event Bus or documented
   public interfaces** — no direct scene-tree reach-across.
5. **Proprietary licensing** for all original code/assets; explicit
   rule against copying names/assets/code from existing titles
   (carried through `CODING_STANDARDS.md`).

Full rationale for each decision is captured as an ADR in `docs/adr/`
so future contributors understand *why*, not just *what*.

## Deliverables This Phase

- Repository folder skeleton (client/server/backend-services/infra/tools/docs)
- `README.md`, `ARCHITECTURE.md`, `CODING_STANDARDS.md`, `CONTRIBUTING.md`
- `MILESTONES.md` roadmap tracker
- `ADR-0001` (engine & stack rationale), `ADR-0002` (identity/nickname system)
- Per-folder `README.md` stubs describing responsibility & interface
  contracts for every feature module (content, not placeholder code)
- `.gitignore`, `LICENSE`, minimal `client/project.godot`

## Explicitly Out of Scope This Phase

- Any gameplay script (belongs to Phase 3+)
- CI/CD pipeline definitions (Phase 2)
- Nakama/Postgres/Redis docker-compose stack (Phase 2)
- Actual Godot scenes/nodes (Phase 3+)

## Testing Checklist

- [ ] Clone repo fresh, confirm folder structure matches `README.md` diagram
- [ ] Open `client/project.godot` in Godot 4.x — project loads without errors, no scenes required yet
- [ ] Every folder under `client/features/`, `client/networking/`,
      `server/modules/` contains a `README.md` — verify via
      `find . -type d -mindepth 2 -maxdepth 3 ! -exec test -e "{}/README.md" \; -print` returns empty for feature dirs
- [ ] `docs/adr/ADR-0001` and `ADR-0002` reviewed and agreed on by both developers (Sukesh D, Rakesh D)

## Next Milestone

**Phase 2 — Repository Setup**: Git initialization with branch
strategy, GitHub remote, `.editorconfig`, CI skeleton (lint + build
check), Godot version pinning via `client/project.godot`
`config/features`, and local Docker Compose stack for Nakama +
PostgreSQL + Redis so Phase 3's core framework has something to
connect to.

