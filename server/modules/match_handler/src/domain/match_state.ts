import type { Vector3 } from "./movement_validation";

export const MAX_HEALTH = 100;

/** Per-player authoritative state tracked by the match handler. */
export interface PlayerMatchState {
  userId: string;
  username: string;
  position: Vector3;
  connected: boolean;
  /** Server tick this player's position was last updated. */
  lastUpdateTick: number;
  health: number;
  eliminated: boolean;
  /** Tracks the last tick each weapon class was fired, for fire-rate validation (ADR-0007). */
  lastFireTickByWeapon: { [weaponClass: string]: number };
}

/**
 * The match handler's full authoritative state. Matches
 * `nkruntime.MatchState`'s index signature by construction (see
 * `infrastructure/match_handler.ts`), but is defined here in the
 * domain layer since nothing about its shape depends on Nakama APIs.
 */
export interface WarzoneMatchState {
  players: { [userId: string]: PlayerMatchState };
  /** Fixed per-match seed for deterministic, shared safe-zone state. */
  zoneSeed: number;
  /** Server tick the match itself started at (for elapsed-time math). */
  matchStartTick: number;
  tickRate: number;
}

export const DEFAULT_MAX_PLAYERS = 50;

// Conservative starting tick rate — see ADR-0006 for why this is
// deliberately not pushed higher until real load-testing (Phase 14)
// justifies it.
export const MATCH_TICK_RATE = 10;
