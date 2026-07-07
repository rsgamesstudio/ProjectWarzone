# Project Warzone

**Studio:** RS GAMES
**Developers:** Sukesh D, Rakesh D
**Engine:** Godot 4.x
**Status:** Phase 1 — Project Architecture (0% gameplay implemented)

Project Warzone is an original third-person battle royale designed for
Android (3 GB RAM minimum) and PC, built on a dedicated authoritative
server model using Nakama, PostgreSQL, and Redis. No assets, code, maps,
or names are copied from any existing title — everything is built from
scratch or sourced from open-license libraries.

## Repository Layout

```
project-warzone/
├── client/            Godot 4 game client (GDScript + C#)
├── server/            Nakama server-side runtime modules (match logic, matchmaking, anti-cheat)
├── backend-services/  Auxiliary services (admin tools, analytics pipeline)
├── infra/             Docker, CI/CD, Kubernetes manifests
├── tools/             Asset pipeline & build automation scripts
└── docs/              Architecture, ADRs, milestones, phase reports
```

Each folder contains its own `README.md` describing its responsibility,
its allowed dependencies, and its public interface. See
[`docs/ARCHITECTURE.md`](ARCHITECTURE.md) for the full system design and
[`docs/milestones/MILESTONES.md`](docs/milestones/MILESTONES.md) for
current progress against the 16-phase roadmap.

## Getting Started (Development)

> Full setup instructions will be added in Phase 2 (Repository Setup &
> Tooling), including Godot version pinning, Nakama Docker Compose
> stack, and Postgres/Redis local dev containers.

## Design Pillars

1. **Server-authoritative** — the client never decides outcomes; it only
   predicts and requests.
2. **Feature isolation** — every gameplay feature is a self-contained
   module with an explicit public interface; nothing reaches into
   another feature's internals.
3. **Scalable from day one** — matchmaking, session state, and match
   simulation are built to move from a single Nakama node to a
   horizontally scaled cluster without a rewrite.
4. **Playable on low-end hardware** — every rendering and networking
   decision considers the 3 GB RAM Android baseline first.

## License

Proprietary — © RS GAMES. All rights reserved. See `LICENSE`.
