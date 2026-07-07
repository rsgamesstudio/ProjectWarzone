extends GutTest
## Unit tests for client/networking/replication/interpolation_buffer.gd.

func test_empty_buffer_returns_zero_vector() -> void:
	var buffer := InterpolationBuffer.new()
	assert_eq(buffer.get_interpolated_position(1.0), Vector3.ZERO)

func test_single_snapshot_returns_that_position_regardless_of_time() -> void:
	var buffer := InterpolationBuffer.new()
	buffer.add_snapshot(1.0, Vector3(5, 0, 5))

	assert_eq(buffer.get_interpolated_position(10.0), Vector3(5, 0, 5))

func test_interpolates_halfway_between_two_snapshots() -> void:
	var buffer := InterpolationBuffer.new()
	buffer.interpolation_delay_seconds = 0.0 # simplify the math for this test
	buffer.add_snapshot(0.0, Vector3(0, 0, 0))
	buffer.add_snapshot(2.0, Vector3(10, 0, 0))

	var result := buffer.get_interpolated_position(1.0)

	assert_almost_eq(result.x, 5.0, 0.01)

func test_render_time_before_earliest_snapshot_clamps_to_earliest() -> void:
	var buffer := InterpolationBuffer.new()
	buffer.interpolation_delay_seconds = 0.0
	buffer.add_snapshot(5.0, Vector3(1, 0, 1))
	buffer.add_snapshot(6.0, Vector3(2, 0, 2))

	var result := buffer.get_interpolated_position(0.0)

	assert_eq(result, Vector3(1, 0, 1))

func test_render_time_after_latest_snapshot_clamps_to_latest() -> void:
	var buffer := InterpolationBuffer.new()
	buffer.interpolation_delay_seconds = 0.0
	buffer.add_snapshot(5.0, Vector3(1, 0, 1))
	buffer.add_snapshot(6.0, Vector3(2, 0, 2))

	var result := buffer.get_interpolated_position(100.0)

	assert_eq(result, Vector3(2, 0, 2))

func test_out_of_order_snapshot_insertion_is_sorted_correctly() -> void:
	var buffer := InterpolationBuffer.new()
	buffer.interpolation_delay_seconds = 0.0
	buffer.add_snapshot(2.0, Vector3(10, 0, 0))
	buffer.add_snapshot(0.0, Vector3(0, 0, 0)) # arrives "late" but is chronologically earlier

	var result := buffer.get_interpolated_position(1.0)

	assert_almost_eq(result.x, 5.0, 0.01)

func test_buffer_caps_at_max_snapshots() -> void:
	var buffer := InterpolationBuffer.new()
	for i in range(InterpolationBuffer.MAX_SNAPSHOTS + 10):
		buffer.add_snapshot(float(i), Vector3(float(i), 0, 0))

	assert_eq(buffer.snapshot_count(), InterpolationBuffer.MAX_SNAPSHOTS)

func test_interpolation_delay_renders_slightly_in_the_past() -> void:
	var buffer := InterpolationBuffer.new()
	buffer.interpolation_delay_seconds = 0.5
	buffer.add_snapshot(0.0, Vector3(0, 0, 0))
	buffer.add_snapshot(1.0, Vector3(10, 0, 0))

	# render_time=1.0 with a 0.5s delay effectively samples at t=0.5,
	# i.e. halfway between the two snapshots.
	var result := buffer.get_interpolated_position(1.0)

	assert_almost_eq(result.x, 5.0, 0.01)
