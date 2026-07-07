# ADR-0002: Unique Identifier & Permanent Nickname System

**Status:** Accepted
**Date:** 2026-07-03

## Context

The brief requires a permanent, unique nickname system (concept
similar to modern online games' handle+tag or reserved-nickname
systems) plus a stable internal UID, across three login methods
(Guest, Google, Email) that can later be linked/upgraded.

## Decision

- **Internal UID**: Nakama's own account ID (UUID) is the source of
  truth for "who this player is" internally. Never exposed in
  matchmaking UI or leaderboards directly.
- **Public Nickname**: a separate, player-chosen, globally-unique
  string stored in PostgreSQL with a case-insensitive uniqueness
  constraint, reserved at creation time via a transactional
  "claim" (check-and-insert in one DB transaction to prevent race
  conditions on popular names).
- **Guest → linked account upgrade**: Guest accounts get an
  auto-generated placeholder nickname (`Player######`) that must be
  claimed as a permanent unique nickname before it can be changed
  again — nickname changes after the first claim are rate-limited and
  auditable (supports future "nickname change item" economy feature
  without re-architecting).
- Nickname validation (length, character set, profanity/impersonation
  filtering) is enforced **server-side only**, in
  `server/modules/authentication/`, never trusted from client input.

## Consequences

- Requires a dedicated Postgres migration for a `nicknames` table with
  a unique index — scheduled for Phase 4.
- Keeps UID and nickname decoupled, so cosmetic/display identity can
  change without breaking foreign keys across inventory, stats, and
  match history tables that reference UID.
