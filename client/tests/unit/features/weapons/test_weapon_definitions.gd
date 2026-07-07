extends GutTest
## Unit tests for client/features/weapons/domain/weapon_definitions.gd.

func test_all_five_weapon_classes_are_defined() -> void:
	var ids: Array = WeaponDefinitions.all_ids()
	assert_eq(ids.size(), 5)
	for expected in ["assault_rifle", "smg", "sniper", "shotgun", "sidearm"]:
		assert_true(ids.has(expected), "expected weapon class '%s' to be defined" % expected)

func test_get_definition_returns_correct_display_name() -> void:
	var rifle: WeaponDefinitions.WeaponDefinition = WeaponDefinitions.get_definition("assault_rifle")
	assert_eq(rifle.display_name, "VK-12")

func test_get_definition_for_unknown_id_returns_null() -> void:
	var result = WeaponDefinitions.get_definition("does_not_exist")
	assert_null(result)

func test_no_weapon_uses_a_real_firearm_name() -> void:
	# Regression guard tied to ADR-0007: real firearm manufacturer
	# names/model numbers carry trademark risk this project has
	# deliberately avoided.
	var forbidden_substrings := ["AK-47", "M4A1", "M16", "AWP", "Barrett", "Glock", "Kalashnikov"]
	for id in WeaponDefinitions.all_ids():
		var def: WeaponDefinitions.WeaponDefinition = WeaponDefinitions.get_definition(id)
		for forbidden in forbidden_substrings:
			assert_false(def.display_name.contains(forbidden), "weapon name '%s' should not reference real firearm '%s'" % [def.display_name, forbidden])

func test_all_weapons_have_positive_stats() -> void:
	for id in WeaponDefinitions.all_ids():
		var def: WeaponDefinitions.WeaponDefinition = WeaponDefinitions.get_definition(id)
		assert_gt(def.base_damage, 0.0, id)
		assert_gt(def.magazine_size, 0, id)
		assert_gt(def.fire_rate_per_second, 0.0, id)
		assert_gt(def.max_range_meters, 0.0, id)
