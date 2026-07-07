extends GutTest
## Unit tests for client/networking/prediction/prediction_buffer.gd.

func test_record_and_get_entry_round_trips() -> void:
	var buffer := PredictionBuffer.new()
	buffer.record(5, Vector3(1, 0, 2), Vector3(0.1, 0, 0.2))

	var entry: PredictionBuffer.Entry = buffer.get_entry(5)

	assert_not_null(entry)
	assert_eq(entry.tick, 5)
	assert_eq(entry.position, Vector3(1, 0, 2))

func test_get_entry_for_missing_tick_returns_null() -> void:
	var buffer := PredictionBuffer.new()
	assert_null(buffer.get_entry(999))

func test_has_entry_reflects_recorded_state() -> void:
	var buffer := PredictionBuffer.new()
	assert_false(buffer.has_entry(1))
	buffer.record(1, Vector3.ZERO, Vector3.ZERO)
	assert_true(buffer.has_entry(1))

func test_get_entries_after_returns_only_later_ticks_in_order() -> void:
	var buffer := PredictionBuffer.new()
	buffer.record(1, Vector3.ZERO, Vector3.ZERO)
	buffer.record(2, Vector3.ONE, Vector3.ONE)
	buffer.record(3, Vector3.ONE * 2, Vector3.ONE)

	var entries: Array[PredictionBuffer.Entry] = buffer.get_entries_after(1)

	assert_eq(entries.size(), 2)
	assert_eq(entries[0].tick, 2)
	assert_eq(entries[1].tick, 3)

func test_discard_up_to_removes_old_entries() -> void:
	var buffer := PredictionBuffer.new()
	buffer.record(1, Vector3.ZERO, Vector3.ZERO)
	buffer.record(2, Vector3.ZERO, Vector3.ZERO)
	buffer.record(3, Vector3.ZERO, Vector3.ZERO)

	buffer.discard_up_to(2)

	assert_false(buffer.has_entry(1))
	assert_false(buffer.has_entry(2))
	assert_true(buffer.has_entry(3))
	assert_eq(buffer.size(), 1)

func test_recording_same_tick_twice_overwrites_without_duplicating() -> void:
	var buffer := PredictionBuffer.new()
	buffer.record(1, Vector3.ZERO, Vector3.ZERO)
	buffer.record(1, Vector3.ONE, Vector3.ONE)

	assert_eq(buffer.size(), 1)
	assert_eq(buffer.get_entry(1).position, Vector3.ONE)

func test_buffer_caps_at_max_entries() -> void:
	var buffer := PredictionBuffer.new()
	for i in range(PredictionBuffer.MAX_ENTRIES + 50):
		buffer.record(i, Vector3.ZERO, Vector3.ZERO)

	assert_eq(buffer.size(), PredictionBuffer.MAX_ENTRIES)
	# Oldest entries should have been evicted first.
	assert_false(buffer.has_entry(0))
	assert_true(buffer.has_entry(PredictionBuffer.MAX_ENTRIES + 49))
