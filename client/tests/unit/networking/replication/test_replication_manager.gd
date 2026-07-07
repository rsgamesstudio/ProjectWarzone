extends GutTest
## Unit tests for client/networking/replication/replication_manager.gd.

func _make_snapshot(elapsed: float, players: Array) -> Dictionary:
	return {"elapsedSeconds": elapsed, "players": players}

func test_ingest_creates_a_buffer_per_remote_player() -> void:
	var manager := ReplicationManager.new()
	var snapshot := _make_snapshot(1.0, [
		{"userId": "player-a", "position": {"x": 1.0, "y": 0.0, "z": 2.0}},
		{"userId": "player-b", "position": {"x": 3.0, "y": 0.0, "z": 4.0}},
	])

	manager.ingest_snapshot(snapshot, "local-player")

	assert_true(manager.has_entity("player-a"))
	assert_true(manager.has_entity("player-b"))
	assert_eq(manager.tracked_entity_count(), 2)

func test_local_player_is_excluded_from_tracking() -> void:
	var manager := ReplicationManager.new()
	var snapshot := _make_snapshot(1.0, [
		{"userId": "local-player", "position": {"x": 1.0, "y": 0.0, "z": 2.0}},
		{"userId": "player-b", "position": {"x": 3.0, "y": 0.0, "z": 4.0}},
	])

	manager.ingest_snapshot(snapshot, "local-player")

	assert_false(manager.has_entity("local-player"))
	assert_true(manager.has_entity("player-b"))

func test_get_interpolated_position_for_unknown_entity_returns_zero() -> void:
	var manager := ReplicationManager.new()
	assert_eq(manager.get_interpolated_position("nobody", 1.0), Vector3.ZERO)

func test_remove_entity_stops_tracking_it() -> void:
	var manager := ReplicationManager.new()
	var snapshot := _make_snapshot(1.0, [
		{"userId": "player-a", "position": {"x": 1.0, "y": 0.0, "z": 2.0}},
	])
	manager.ingest_snapshot(snapshot, "local-player")
	assert_true(manager.has_entity("player-a"))

	manager.remove_entity("player-a")

	assert_false(manager.has_entity("player-a"))

func test_malformed_snapshot_missing_players_does_not_crash() -> void:
	var manager := ReplicationManager.new()
	manager.ingest_snapshot({"elapsedSeconds": 1.0}, "local-player")
	assert_eq(manager.tracked_entity_count(), 0)
