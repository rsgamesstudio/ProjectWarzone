extends GutTest
## Unit tests for client/features/weapons/domain/damage_calculator.gd.

var rifle: WeaponDefinitions.WeaponDefinition

func before_each() -> void:
	rifle = WeaponDefinitions.get_definition("assault_rifle")

func test_full_damage_within_falloff_start() -> void:
	var damage := DamageCalculator.calculate_damage(rifle, 5.0)
	assert_eq(damage, rifle.base_damage)

func test_minimum_damage_beyond_falloff_end() -> void:
	var damage := DamageCalculator.calculate_damage(rifle, rifle.falloff_end_meters + 100.0)
	assert_almost_eq(damage, rifle.base_damage * rifle.min_damage_fraction, 0.01)

func test_damage_decreases_through_falloff_range() -> void:
	var near := DamageCalculator.calculate_damage(rifle, rifle.falloff_start_meters + 5.0)
	var far := DamageCalculator.calculate_damage(rifle, rifle.falloff_end_meters - 5.0)
	assert_gt(near, far)

func test_matches_server_side_calculation_at_a_known_point() -> void:
	# Cross-check against the server's damage_calculator.test.ts
	# "halfway through falloff range" case for the same weapon —
	# these two implementations must agree since they're meant to be
	# mirrors of each other.
	var midpoint: float = (rifle.falloff_start_meters + rifle.falloff_end_meters) / 2.0
	var damage := DamageCalculator.calculate_damage(rifle, midpoint)
	var expected_mid_damage: float = (rifle.base_damage + rifle.base_damage * rifle.min_damage_fraction) / 2.0
	assert_almost_eq(damage, expected_mid_damage, 0.01)
