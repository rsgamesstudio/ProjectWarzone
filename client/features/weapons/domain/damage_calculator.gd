class_name DamageCalculator
extends RefCounted
## Client-side mirror of
## server/modules/match_handler/src/domain/damage_calculator.ts —
## used only for client-side UI prediction (e.g. showing an estimated
## damage number immediately on hit-marker feedback before the
## server's authoritative DamageEvent arrives). The server's number
## always wins; see ADR-0007.

static func calculate_damage(weapon: WeaponDefinitions.WeaponDefinition, distance_meters: float) -> float:
	if distance_meters <= weapon.falloff_start_meters:
		return weapon.base_damage

	var min_damage: float = weapon.base_damage * weapon.min_damage_fraction

	if distance_meters >= weapon.falloff_end_meters:
		return min_damage

	var falloff_range: float = weapon.falloff_end_meters - weapon.falloff_start_meters
	var distance_into_falloff: float = distance_meters - weapon.falloff_start_meters
	var fraction: float = distance_into_falloff / falloff_range

	return weapon.base_damage - (weapon.base_damage - min_damage) * fraction
