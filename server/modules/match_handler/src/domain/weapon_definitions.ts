/**
 * Weapon class definitions. All names are original and fictional —
 * no real firearm manufacturer names/model numbers — see ADR-0007 for
 * why (real gun names carry actual trademark/licensing risk).
 *
 * This is the SAME data both client and server need; kept here as the
 * server's authoritative copy. The client mirrors these values in
 * `client/features/weapons/domain/weapon_definitions.gd` for its own
 * local prediction/UI — same manual-sync caveat as
 * `match_opcodes.ts`/`match_opcodes.gd`.
 */

export type WeaponClass = "assault_rifle" | "smg" | "sniper" | "shotgun" | "sidearm";

export interface WeaponDefinition {
  id: WeaponClass;
  displayName: string;
  baseDamage: number;
  /** Meters within which baseDamage applies at full value. */
  falloffStartMeters: number;
  /** Meters beyond which damage bottoms out at minDamageFraction * baseDamage. */
  falloffEndMeters: number;
  minDamageFraction: number;
  fireRatePerSecond: number;
  magazineSize: number;
  reloadSeconds: number;
  /** Absolute max range — hits claimed beyond this are never plausible (ADR-0007). */
  maxRangeMeters: number;
}

export const WEAPON_DEFINITIONS: Record<WeaponClass, WeaponDefinition> = {
  assault_rifle: {
    id: "assault_rifle",
    displayName: "VK-12",
    baseDamage: 28,
    falloffStartMeters: 25,
    falloffEndMeters: 80,
    minDamageFraction: 0.55,
    fireRatePerSecond: 8,
    magazineSize: 30,
    reloadSeconds: 2.3,
    maxRangeMeters: 120,
  },
  smg: {
    id: "smg",
    displayName: "Wisp SMG",
    baseDamage: 20,
    falloffStartMeters: 12,
    falloffEndMeters: 40,
    minDamageFraction: 0.5,
    fireRatePerSecond: 12,
    magazineSize: 25,
    reloadSeconds: 1.8,
    maxRangeMeters: 55,
  },
  sniper: {
    id: "sniper",
    displayName: "Longbow",
    baseDamage: 85,
    falloffStartMeters: 60,
    falloffEndMeters: 200,
    minDamageFraction: 0.7,
    fireRatePerSecond: 0.75,
    magazineSize: 5,
    reloadSeconds: 3.2,
    maxRangeMeters: 300,
  },
  shotgun: {
    id: "shotgun",
    displayName: "Reaper-12",
    baseDamage: 70,
    falloffStartMeters: 6,
    falloffEndMeters: 20,
    minDamageFraction: 0.2,
    fireRatePerSecond: 1.2,
    magazineSize: 8,
    reloadSeconds: 3.5,
    maxRangeMeters: 25,
  },
  sidearm: {
    id: "sidearm",
    displayName: "Talon Pistol",
    baseDamage: 22,
    falloffStartMeters: 15,
    falloffEndMeters: 45,
    minDamageFraction: 0.5,
    fireRatePerSecond: 5,
    magazineSize: 12,
    reloadSeconds: 1.5,
    maxRangeMeters: 60,
  },
};

export function getWeaponDefinition(weaponClass: WeaponClass): WeaponDefinition {
  const definition = WEAPON_DEFINITIONS[weaponClass];
  if (!definition) {
    throw new Error(`Unknown weapon class: ${weaponClass}`);
  }
  return definition;
}
