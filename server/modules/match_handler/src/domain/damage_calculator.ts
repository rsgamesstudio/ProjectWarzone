import type { WeaponDefinition } from "./weapon_definitions";

/**
 * Computes damage for a hit at `distanceMeters`, applying linear
 * falloff between the weapon's falloffStartMeters and
 * falloffEndMeters. Pure function — no Nakama dependency.
 */
export function calculateDamage(weapon: WeaponDefinition, distanceMeters: number): number {
  if (distanceMeters <= weapon.falloffStartMeters) {
    return weapon.baseDamage;
  }

  const minDamage = weapon.baseDamage * weapon.minDamageFraction;

  if (distanceMeters >= weapon.falloffEndMeters) {
    return minDamage;
  }

  const falloffRange = weapon.falloffEndMeters - weapon.falloffStartMeters;
  const distanceIntoFalloff = distanceMeters - weapon.falloffStartMeters;
  const fraction = distanceIntoFalloff / falloffRange;

  return weapon.baseDamage - (weapon.baseDamage - minDamage) * fraction;
}
