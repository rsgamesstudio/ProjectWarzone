import type { Vector3 } from "./movement_validation";

/**
 * Safe-zone shrink schedule — pure math, no Nakama dependency. The
 * match handler calls this every tick with elapsed match time and
 * gets back the authoritative zone state to broadcast; it never
 * mutates or stores zone logic itself.
 *
 * Deterministic given the same `seed`: two calls with the same seed
 * and elapsed time always produce the same zone center, which is
 * required for the server to be authoritative (every player must see
 * the identical zone) and makes this fully unit-testable without any
 * randomness flakiness.
 */

export interface ZonePhase {
  /** Seconds after match start this phase's shrink completes. */
  endsAtSeconds: number;
  /** Zone radius (meters) once this phase's shrink is complete. */
  radiusMeters: number;
}

// Deliberately conservative for an initial implementation — real
// values get tuned against Meridian's actual dimensions once that
// map exists (Phase 10). Five phases, matching the "safe zone
// shrinking system" requirement without overfitting numbers we can't
// playtest yet.
export const ZONE_PHASES: ZonePhase[] = [
  { endsAtSeconds: 90, radiusMeters: 500 },
  { endsAtSeconds: 180, radiusMeters: 300 },
  { endsAtSeconds: 270, radiusMeters: 150 },
  { endsAtSeconds: 360, radiusMeters: 60 },
  { endsAtSeconds: 420, radiusMeters: 20 },
];

export const INITIAL_RADIUS_METERS = 800;
export const MATCH_CENTER: Vector3 = { x: 0, y: 0, z: 0 };

export interface ZoneState {
  center: Vector3;
  radiusMeters: number;
  phaseIndex: number; // -1 before the first shrink begins
  nextShrinkAtSeconds: number | null; // null once all phases are complete
}

/**
 * Simple deterministic PRNG (mulberry32) — good enough for picking a
 * reproducible next zone center; this is gameplay flavor, not
 * cryptography, so a lightweight dependency-free generator is the
 * right tool rather than pulling in a crypto-grade RNG.
 */
function mulberry32(seed: number): () => number {
  let state = seed;
  return function (): number {
    state |= 0;
    state = (state + 0x6d2b79f5) | 0;
    let t = Math.imul(state ^ (state >>> 15), 1 | state);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Deterministically derives phase N's center from the match seed. */
function centerForPhase(seed: number, phaseIndex: number, previousRadius: number): Vector3 {
  if (phaseIndex < 0) {
    return MATCH_CENTER;
  }
  const rng = mulberry32(seed + phaseIndex * 7919); // distinct stream per phase
  const angle = rng() * Math.PI * 2;
  // New center stays within the previous zone's radius so the next
  // zone is always at least partially inside the current one.
  const maxOffset = previousRadius * 0.5;
  const offset = rng() * maxOffset;
  return {
    x: MATCH_CENTER.x + Math.cos(angle) * offset,
    y: MATCH_CENTER.y,
    z: MATCH_CENTER.z + Math.sin(angle) * offset,
  };
}

/**
 * Computes the authoritative zone state at a given elapsed match
 * time. `seed` should be fixed per-match (e.g. derived from the match
 * ID) so every player's client renders the identical zone.
 *
 * The radius linearly interpolates from the previous phase's radius
 * down to the current phase's target radius over the course of that
 * phase's duration — a real shrink, not a sudden jump at the phase
 * boundary.
 */
export function getZoneStateAtElapsedSeconds(elapsedSeconds: number, seed: number): ZoneState {
  if (elapsedSeconds < 0) {
    return {
      center: MATCH_CENTER,
      radiusMeters: INITIAL_RADIUS_METERS,
      phaseIndex: -1,
      nextShrinkAtSeconds: ZONE_PHASES[0]?.endsAtSeconds ?? null,
    };
  }

  let previousRadius = INITIAL_RADIUS_METERS;
  let phaseStartSeconds = 0;

  for (let i = 0; i < ZONE_PHASES.length; i++) {
    const phase = ZONE_PHASES[i];
    if (elapsedSeconds < phase.endsAtSeconds) {
      const phaseDuration = phase.endsAtSeconds - phaseStartSeconds;
      const fraction = phaseDuration > 0 ? (elapsedSeconds - phaseStartSeconds) / phaseDuration : 1;
      const radius = previousRadius + (phase.radiusMeters - previousRadius) * fraction;
      return {
        center: centerForPhase(seed, i, previousRadius),
        radiusMeters: radius,
        phaseIndex: i,
        nextShrinkAtSeconds: phase.endsAtSeconds,
      };
    }
    previousRadius = phase.radiusMeters;
    phaseStartSeconds = phase.endsAtSeconds;
  }

  // All phases complete — final, smallest zone, no further shrink.
  const lastIndex = ZONE_PHASES.length - 1;
  return {
    center: centerForPhase(seed, lastIndex, previousRadius),
    radiusMeters: previousRadius,
    phaseIndex: lastIndex,
    nextShrinkAtSeconds: null,
  };
}
