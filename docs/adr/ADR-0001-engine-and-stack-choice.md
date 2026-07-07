# ADR-0001: Engine & Core Stack Choice

**Status:** Accepted
**Date:** 2026-07-03

## Context

Project Warzone needs an engine and backend stack that can support a
50-player (scaling further) third-person battle royale, run on 3 GB
RAM Android devices, and be developed by a small team over 1+ years
without proprietary engine licensing overhead.

## Decision

- **Godot 4** as the client engine: open source, no per-seat/royalty
  licensing, strong 3D pipeline (Vulkan renderer with mobile
  fallback), native GDScript for iteration speed and C# interop for
  performance-critical systems.
- **Nakama** as the dedicated multiplayer server: open-source,
  self-hostable, built-in matchmaker, authoritative match handler
  runtime, proven at scale, avoids vendor lock-in vs. closed
  commercial BaaS.
- **Firebase (Auth/FCM/Analytics only)**: fastest path to reliable
  Guest/Google/Email login and push notifications without building
  federated auth from scratch; deliberately not used for gameplay
  state to avoid split-brain authority with Nakama.
- **PostgreSQL** for durable player/economy data (ACID guarantees
  matter for inventory/currency); **Redis** for ephemeral
  matchmaking/session/presence data where latency matters more than
  durability.

## Alternatives Considered

- **Unreal Engine**: stronger out-of-box AAA visual fidelity, but
  heavier on low-end Android (3 GB RAM target) and steeper C++
  iteration cost for a small team.
- **Unity**: mature mobile pipeline, but licensing/runtime-fee
  uncertainty in recent years was judged a long-term risk for a 1+
  year self-funded project.
- **Custom backend instead of Nakama**: full control, but would
  consume months of the roadmap rebuilding matchmaking/session
  primitives Nakama already provides and battle-tests.

## Consequences

- Team must budget time for Godot 4's less mature large-scale
  multiplayer tooling compared to Unreal/Unity — mitigated by keeping
  networking logic in `client/networking/` behind clean interfaces so
  the transport can be revisited without a full rewrite if needed.
- Two backend "identity" surfaces (Firebase + Nakama sessions) require
  a documented bridging flow — captured in Phase 4 (Authentication).
