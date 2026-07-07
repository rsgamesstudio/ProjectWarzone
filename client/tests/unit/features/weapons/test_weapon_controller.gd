extends GutTest
## Unit tests for client/features/weapons/application/weapon_controller.gd.

var controller: WeaponController

func before_each() -> void:
	# sidearm: fire_rate 5/s, magazine 12, reload 1.5s — convenient round numbers for testing.
	controller = WeaponController.new(WeaponDefinitions.get_definition("sidearm"))

func test_starts_with_a_full_magazine() -> void:
	assert_eq(controller.current_ammo, 12)

func test_try_fire_consumes_one_round() -> void:
	controller.try_fire()
	assert_eq(controller.current_ammo, 11)

func test_try_fire_returns_true_when_allowed() -> void:
	assert_true(controller.try_fire())

func test_try_fire_respects_fire_rate_cooldown() -> void:
	controller.try_fire()
	# Immediately trying again, with no time elapsed, should fail —
	# sidearm fires 5/s, i.e. needs 0.2s between shots.
	assert_false(controller.try_fire())
	assert_eq(controller.current_ammo, 11, "a rejected fire attempt must not consume ammo")

func test_try_fire_succeeds_again_after_cooldown_elapses() -> void:
	controller.try_fire()
	controller.tick(0.25) # > 0.2s cooldown for a 5/s fire rate
	assert_true(controller.try_fire())
	assert_eq(controller.current_ammo, 10)

func test_cannot_fire_with_empty_magazine() -> void:
	for i in range(12):
		controller.try_fire()
		controller.tick(1.0) # clear cooldown each time so we actually empty the mag
	assert_eq(controller.current_ammo, 0)
	assert_false(controller.try_fire())

func test_start_reload_sets_reloading_state() -> void:
	controller.try_fire()
	controller.start_reload()
	assert_true(controller.is_reloading)

func test_cannot_fire_while_reloading() -> void:
	controller.try_fire() # must not be at a full magazine, or start_reload() below is a no-op
	controller.start_reload()
	assert_false(controller.try_fire())

func test_reload_refills_magazine_after_reload_time_elapses() -> void:
	controller.try_fire()
	controller.try_fire()
	controller.tick(1.0) # clear cooldown
	controller.start_reload()
	controller.tick(1.5) # exactly the sidearm's reload_seconds
	assert_false(controller.is_reloading)
	assert_eq(controller.current_ammo, 12)

func test_reload_does_not_complete_early() -> void:
	controller.try_fire()
	controller.start_reload()
	controller.tick(0.5) # well under the 1.5s reload time
	assert_true(controller.is_reloading)

func test_start_reload_is_a_noop_when_already_full() -> void:
	controller.start_reload()
	assert_false(controller.is_reloading, "reloading a full magazine should be a no-op")

func test_start_reload_is_a_noop_when_already_reloading() -> void:
	controller.try_fire()
	controller.start_reload()
	var progress_before := controller.reload_progress()
	controller.start_reload() # calling again shouldn't restart the timer
	controller.tick(0.1)
	var progress_after := controller.reload_progress()
	assert_gt(progress_after, progress_before, "reload should keep progressing, not reset")

func test_can_fire_reflects_full_state_machine() -> void:
	assert_true(controller.can_fire())
	controller.try_fire() # must not be at a full magazine, or start_reload() below is a no-op
	controller.start_reload()
	assert_false(controller.can_fire(), "should be false while reloading, even though ammo/cooldown alone would otherwise allow it")

func test_reload_progress_is_zero_when_not_reloading() -> void:
	assert_eq(controller.reload_progress(), 0.0)

func test_reload_progress_increases_toward_one() -> void:
	controller.try_fire()
	controller.start_reload()
	controller.tick(0.75) # halfway through 1.5s
	assert_almost_eq(controller.reload_progress(), 0.5, 0.05)
