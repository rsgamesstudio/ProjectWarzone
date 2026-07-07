import { validateHitPlausibility } from "../domain/hit_validation";
import { calculateDamage } from "../domain/damage_calculator";
import { getWeaponDefinition, type WeaponClass } from "../domain/weapon_definitions";
import { MAX_HEALTH, type PlayerMatchState } from "../domain/match_state";

export interface WeaponFireClaim {
  targetId: string;
  weaponClass: WeaponClass;
  claimedDistanceMeters: number;
}

export type HandleWeaponFireResult =
  | {
      accepted: true;
      updatedShooter: PlayerMatchState;
      updatedTarget: PlayerMatchState;
      damageDealt: number;
      targetEliminated: boolean;
    }
  | { accepted: false; reason: string };

/**
 * Validates and applies one weapon fire claim. Pure orchestration
 * over `validateHitPlausibility`/`calculateDamage` — no Nakama API
 * calls, fully testable. See ADR-0007 for the "plausibility, not full
 * re-simulation" hit registration model this implements.
 */
export function handleWeaponFire(
  shooter: PlayerMatchState,
  target: PlayerMatchState,
  claim: WeaponFireClaim,
  currentTick: number,
  tickRate: number
): HandleWeaponFireResult {
  if (target.eliminated) {
    return { accepted: false, reason: "target is already eliminated" };
  }

  const weapon = getWeaponDefinition(claim.weaponClass);

  const lastFireTick = shooter.lastFireTickByWeapon[claim.weaponClass];
  const secondsSinceLastShot =
    lastFireTick !== undefined ? (currentTick - lastFireTick) / tickRate : null;

  const validation = validateHitPlausibility(
    shooter.position,
    target.position,
    claim.claimedDistanceMeters,
    weapon,
    secondsSinceLastShot
  );

  if (!validation.plausible) {
    return { accepted: false, reason: validation.reason ?? "implausible hit claim" };
  }

  const damage = calculateDamage(weapon, claim.claimedDistanceMeters);
  const remainingHealth = Math.max(0, target.health - damage);
  const targetEliminated = remainingHealth <= 0;

  const updatedShooter: PlayerMatchState = {
    ...shooter,
    lastFireTickByWeapon: { ...shooter.lastFireTickByWeapon, [claim.weaponClass]: currentTick },
  };

  const updatedTarget: PlayerMatchState = {
    ...target,
    health: remainingHealth,
    eliminated: targetEliminated,
  };

  return {
    accepted: true,
    updatedShooter,
    updatedTarget,
    damageDealt: damage,
    targetEliminated,
  };
}

export function createFreshPlayerHealth(): { health: number; eliminated: boolean } {
  return { health: MAX_HEALTH, eliminated: false };
}
