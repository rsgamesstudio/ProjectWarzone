extends GutTest
## Integration test for the real `Services`/`Bootstrap` autoloads as
## configured in project.godot — unlike test_service_container.gd and
## test_event_bus.gd (which instantiate the scripts directly for
## isolated unit testing), this test exercises the actual global
## singletons to catch autoload-order regressions that unit tests
## against a fresh instance cannot see.

func test_bootstrap_registered_event_bus_into_services() -> void:
	assert_true(
		Services.has_service("EventBus"),
		"Bootstrap._ready() should have registered 'EventBus' into Services before this test runs"
	)

func test_resolved_event_bus_is_the_correct_type() -> void:
	var bus: Variant = Services.resolve("EventBus")
	assert_true(bus is EventBus, "the registered 'EventBus' service should be an EventBus instance")

func test_event_bus_service_is_a_singleton_not_recreated_per_resolve() -> void:
	var first: Variant = Services.resolve("EventBus")
	var second: Variant = Services.resolve("EventBus")
	assert_eq(first, second, "resolving 'EventBus' twice should return the same instance, not a new one")

func test_bootstrap_registered_nakama_client_into_services() -> void:
	assert_true(
		Services.has_service("NakamaClient"),
		"Bootstrap._ready() should have registered 'NakamaClient' into Services before this test runs"
	)

func test_resolved_nakama_client_is_the_correct_type() -> void:
	var client: Variant = Services.resolve("NakamaClient")
	assert_true(client is NakamaClientAdapter, "the registered 'NakamaClient' service should be a NakamaClientAdapter instance")

func test_bootstrap_registered_music_player_into_services() -> void:
	assert_true(
		Services.has_service("MusicPlayer"),
		"Bootstrap._ready() should have registered 'MusicPlayer' into Services before this test runs"
	)

func test_resolved_music_player_is_the_correct_type() -> void:
	var player: Variant = Services.resolve("MusicPlayer")
	assert_true(player is MusicPlayer, "the registered 'MusicPlayer' service should be a MusicPlayer instance")

func test_music_player_is_actually_in_the_scene_tree() -> void:
	var player: MusicPlayer = Services.resolve("MusicPlayer")
	assert_not_null(player.get_parent(), "MusicPlayer must be added to the scene tree (as a child of Bootstrap) to play audio at all")
