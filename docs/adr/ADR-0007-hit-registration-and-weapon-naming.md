# ADR-0007: Hit Registration Model & Weapon Naming

**Status:** Accepted
**Date:** 2026-07-05

## Context

Weapons need authoritative damage per this project's security rules
(never trust the client for damage). But Nakama has no physics engine
and no replicated level geometry server-side — the match handler only
knows player positions from the movement snapshots already built in
Phase 5. Full server-side raycasting against real level geometry
(what a client does locally) is not possible without building and
maintaining a parallel physics representation on the server, which is
a much larger undertaking than this phase's scope.

Separately: real firearm names (AK-47, M4A1, Barrett, etc.) carry
actual trademark/licensing risk — several manufacturers have pursued
trademark claims against game studios for unlicensed use of real gun
names and likenesses. This project already has a blanket rule against
copying names from existing titles; the same caution extends to real
firearm brands.

## Decision

**Hit registration**: client-reported hits with server-side
*plausibility* validation, not full server-side raycasting:

- The client performs its own raycast locally (against its own level
  geometry) for immediate visual feedback and reports a claimed hit
  (target user ID, distance, weapon ID, timestamp) to the server.
- The server validates the claim is *plausible* given data it already
  has: the shooter's and target's last-known authoritative positions
  (from the existing snapshot system), the weapon's max range, and
  the weapon's fire-rate cooldown — rejecting claims that are
  geometrically impossible (target too far away, shooter facing the
  wrong way beyond a tolerance, firing faster than the weapon allows)
  even without knowing the exact level geometry.
- This is NOT full lag-compensated server-side hit detection (which
  would require replicating level collision server-side) — it is
  server-side *sanity checking* of a client's claim. Documented here
  explicitly so nobody mistakes this for the server literally
  recomputing the raycast.
- Revisit trigger: if playtesting (Phase 14) reveals this plausibility
  check is too permissive (exploitable) or too strict (rejects
  legitimate hits), tighten the tolerance values first before
  considering a heavier architecture change.

**Weapon naming**: entirely original, fictional names — no real
firearm manufacturer names/model numbers. See `domain/weapon_definitions`
in both client and server for the actual names chosen.

## Consequences

- Damage numbers are still authoritative (the server decides the
  final damage applied, health, and eliminations) even though hit
  *detection* trusts the client's geometric claim within bounds — this
  is a deliberate, bounded trust decision, not a security oversight.
- If this project later wants stronger anti-cheat guarantees for hit
  registration specifically, the next step would be replicating a
  simplified collision representation of Meridian server-side (once
  Meridian exists — Phase 10) rather than trusting client raycasts at
  all. Not undertaken now because there's no map to replicate yet.
