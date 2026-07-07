extends GutTest
## Unit tests for client/networking/reconciliation/reconciler.gd.

func test_small_divergence_is_ignored() -> void:
	var predicted := Vector3(10, 0, 10)
	var server := Vector3(10.05, 0, 10.0) # 5cm off — well under the threshold

	var result := Reconciler.reconcile(predicted, server)

	assert_false(result.needs_correction)
	assert_eq(result.corrected_position, predicted)

func test_large_divergence_triggers_correction() -> void:
	var predicted := Vector3(10, 0, 10)
	var server := Vector3(15, 0, 10) # 5m off — a real desync

	var result := Reconciler.reconcile(predicted, server)

	assert_true(result.needs_correction)
	assert_eq(result.corrected_position, server)

func test_divergence_exactly_at_threshold_is_not_corrected() -> void:
	var predicted := Vector3.ZERO
	var server := Vector3(Reconciler.CORRECTION_THRESHOLD_METERS, 0, 0)

	var result := Reconciler.reconcile(predicted, server)

	assert_false(result.needs_correction)

func test_divergence_value_is_reported_accurately() -> void:
	var predicted := Vector3.ZERO
	var server := Vector3(3, 0, 4) # 3-4-5 triangle => distance 5

	var result := Reconciler.reconcile(predicted, server)

	assert_almost_eq(result.divergence_meters, 5.0, 0.001)

func test_replay_with_no_entries_returns_corrected_position_unchanged() -> void:
	var corrected := Vector3(1, 0, 1)
	var result := Reconciler.replay(corrected, [])
	assert_eq(result, corrected)

func test_replay_applies_each_buffered_input_delta_in_order() -> void:
	var corrected := Vector3.ZERO
	var e1 := PredictionBuffer.Entry.new(1, Vector3.ZERO, Vector3(1, 0, 0))
	var e2 := PredictionBuffer.Entry.new(2, Vector3.ZERO, Vector3(0, 0, 1))

	var result := Reconciler.replay(corrected, [e1, e2])

	assert_eq(result, Vector3(1, 0, 1))
