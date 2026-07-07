extends GutTest
## Unit tests for client/features/character_controller/domain/server_tick_estimator.gd.

func test_initial_estimate_is_zero_before_any_sync() -> void:
	var estimator := ServerTickEstimator.new(10)
	assert_eq(estimator.estimate_current_tick(), 0)

func test_resync_sets_estimate_to_authoritative_tick() -> void:
	var estimator := ServerTickEstimator.new(10)
	estimator.resync(500)
	assert_eq(estimator.estimate_current_tick(), 500)

func test_advance_increases_estimate_at_the_configured_tick_rate() -> void:
	var estimator := ServerTickEstimator.new(10) # 10 ticks/sec
	estimator.resync(100)
	estimator.advance(1.0) # 1 second elapsed => 10 ticks
	assert_eq(estimator.estimate_current_tick(), 110)

func test_advance_can_be_called_incrementally() -> void:
	var estimator := ServerTickEstimator.new(10)
	estimator.resync(0)
	for i in range(10):
		estimator.advance(0.1) # 10 x 0.1s = 1s total
	assert_eq(estimator.estimate_current_tick(), 10)

func test_resync_resets_accumulated_drift() -> void:
	var estimator := ServerTickEstimator.new(10)
	estimator.resync(0)
	estimator.advance(5.0) # estimate way ahead now
	estimator.resync(50) # server says we're actually at 50
	assert_eq(estimator.estimate_current_tick(), 50)

func test_different_tick_rates_produce_different_estimates_for_same_elapsed_time() -> void:
	var slow := ServerTickEstimator.new(5)
	var fast := ServerTickEstimator.new(20)
	slow.resync(0)
	fast.resync(0)
	slow.advance(1.0)
	fast.advance(1.0)
	assert_lt(slow.estimate_current_tick(), fast.estimate_current_tick())
