import type { Vector3 } from "./movement_validation";
import type { WeaponDefinition } from "./weapon_definitions";

/**
 * Validates that a client-reported weapon hit is PLAUSIBLE given data
 * the server already has — NOT a full re-simulation of the shot (see
 * ADR-0007 for why: Nakama has no server-side physics/level geometry
 * to raycast against). Pure function — no Nakama dependency.
 */

export interface HitPlausibilityResult {
  plausible: boolean;
  reason: string | null;
}

function distance(a: Vector3, b: Vector3): number {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const dz = b.z - a.z;
  return Math.sqrt(dx * dx + dy * dy + dz * dz);
}

// Absorbs the fact that both positions come from periodic snapshots,
// not the exact instant the shot was fired — not a license to extend
// weapon range, just slack for legitimate staleness.
const DISTANCE_TOLERANCE_METERS = 3.0;
const FIRE_RATE_TOLERANCE_FRACTION = 0.85; // allow firing slightly early due to jitter, not a lot

export function validateHitPlausibility(
  shooterPosition: Vector3,
  targetPosition: Vector3,
  claimedDistanceMeters: number,
  weapon: WeaponDefinition,
  secondsSinceLastShotFromThisWeapon: number | null
): HitPlausibilityResult {
  const actualDistance = distance(shooterPosition, targetPosition);

  if (actualDistance > weapon.maxRangeMeters + DISTANCE_TOLERANCE_METERS) {
    return { plausible: false, reason: "target is beyond the weapon's maximum range" };
  }

  if (Math.abs(actualDistance - claimedDistanceMeters) > DISTANCE_TOLERANCE_METERS) {
    return {
      plausible: false,
      reason: "claimed distance does not match last-known positions closely enough",
    };
  }

  if (secondsSinceLastShotFromThisWeapon !== null) {
    const minSecondsBetweenShots = (1 / weapon.fireRatePerSecond) * FIRE_RATE_TOLERANCE_FRACTION;
    if (secondsSinceLastShotFromThisWeapon < minSecondsBetweenShots) {
      return { plausible: false, reason: "firing faster than the weapon's fire rate allows" };
    }
  }

  return { plausible: true, reason: null };
}
