class_name WeaponDefinitions
extends RefCounted
## Client-side mirror of
## server/modules/match_handler/src/domain/weapon_definitions.ts —
## used for local prediction (ammo/cooldown UX, client-side raycast
## for immediate visual feedback) and UI display. The SERVER is
## authoritative for actual damage (see ADR-0007); this data existing
## client-side too is purely so the client doesn't have to wait for a
## round trip to know its own fire rate/magazine size.
##
## MUST stay in sync with the server's copy by hand — same
## manual-sync caveat as match_opcodes.gd. All names are original,
## fictional weapon names — no real firearm manufacturer names/model
## numbers (see ADR-0007).

class WeaponDefinition:
	var id: String
	var display_name: String
	var base_damage: float
	var falloff_start_meters: float
	var falloff_end_meters: float
	var min_damage_fraction: float
	var fire_rate_per_second: float
	var magazine_size: int
	var reload_seconds: float
	var max_range_meters: float

	func _init(
		p_id: String, p_display_name: String, p_base_damage: float,
		p_falloff_start_meters: float, p_falloff_end_meters: float, p_min_damage_fraction: float,
		p_fire_rate_per_second: float, p_magazine_size: int, p_reload_seconds: float,
		p_max_range_meters: float
	) -> void:
		id = p_id
		display_name = p_display_name
		base_damage = p_base_damage
		falloff_start_meters = p_falloff_start_meters
		falloff_end_meters = p_falloff_end_meters
		min_damage_fraction = p_min_damage_fraction
		fire_rate_per_second = p_fire_rate_per_second
		magazine_size = p_magazine_size
		reload_seconds = p_reload_seconds
		max_range_meters = p_max_range_meters

static var _definitions: Dictionary = {}

static func _ensure_initialized() -> void:
	if not _definitions.is_empty():
		return
	_definitions["assault_rifle"] = WeaponDefinition.new(
		"assault_rifle", "VK-12", 28.0, 25.0, 80.0, 0.55, 8.0, 30, 2.3, 120.0
	)
	_definitions["smg"] = WeaponDefinition.new(
		"smg", "Wisp SMG", 20.0, 12.0, 40.0, 0.5, 12.0, 25, 1.8, 55.0
	)
	_definitions["sniper"] = WeaponDefinition.new(
		"sniper", "Longbow", 85.0, 60.0, 200.0, 0.7, 0.75, 5, 3.2, 300.0
	)
	_definitions["shotgun"] = WeaponDefinition.new(
		"shotgun", "Reaper-12", 70.0, 6.0, 20.0, 0.2, 1.2, 8, 3.5, 25.0
	)
	_definitions["sidearm"] = WeaponDefinition.new(
		"sidearm", "Talon Pistol", 22.0, 15.0, 45.0, 0.5, 5.0, 12, 1.5, 60.0
	)

static func get_definition(weapon_id: String) -> WeaponDefinition:
	_ensure_initialized()
	if not _definitions.has(weapon_id):
		push_error("WeaponDefinitions: unknown weapon id '%s'" % weapon_id)
		return null
	return _definitions[weapon_id]

static func all_ids() -> Array:
	_ensure_initialized()
	return _definitions.keys()
