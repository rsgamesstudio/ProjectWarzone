extends GutTest
## Unit tests for client/features/lobby/infrastructure/mock_lobby_data_provider.gd
## and the domain value objects it builds.

func test_view_model_has_expected_player_fields() -> void:
	var provider := MockLobbyDataProvider.new()
	var view_model := provider.get_view_model()

	assert_eq(view_model.player_name, "RS_GAMER")
	assert_eq(view_model.player_level, 45)

func test_view_model_currencies_are_non_negative() -> void:
	var provider := MockLobbyDataProvider.new()
	var view_model := provider.get_view_model()

	assert_gte(view_model.credits, 0)
	assert_gte(view_model.marks, 0)

func test_view_model_includes_at_least_one_mode() -> void:
	var provider := MockLobbyDataProvider.new()
	var view_model := provider.get_view_model()

	assert_true(view_model.modes.size() > 0)

func test_season_path_progress_is_within_valid_range() -> void:
	var provider := MockLobbyDataProvider.new()
	var view_model := provider.get_view_model()

	assert_gte(view_model.season_path_progress, 0.0)
	assert_lte(view_model.season_path_progress, 1.0)

func test_vip_tier_is_non_negative() -> void:
	var provider := MockLobbyDataProvider.new()
	var view_model := provider.get_view_model()

	assert_gte(view_model.vip_tier, 0)

func test_world_chat_message_is_present() -> void:
	var provider := MockLobbyDataProvider.new()
	var view_model := provider.get_view_model()

	assert_false(view_model.world_chat_message.is_empty())

func test_modes_use_original_names_not_trademarked_ones() -> void:
	var provider := MockLobbyDataProvider.new()
	var view_model := provider.get_view_model()

	# Regression guard: this project has an explicit rule against
	# using names/mechanics from existing commercial titles (see
	# ADR-0005). This test exists specifically to catch a future
	# accidental copy-paste of a real trademarked/branded name back
	# into the mock data — includes both Call of Duty map/mode names
	# and Free Fire branded mechanic names caught in a later reference
	# image review.
	var forbidden_names := [
		"Verdansk", "Rebirth Island", "Rust", "Plunder", "Blood Money",
		"Luck Royale", "Shadow Strike", "Warzone Championship", "Warzone Royale",
	]
	for mode: LobbyModeEntry in view_model.modes:
		for forbidden in forbidden_names:
			assert_ne(mode.map_name, forbidden)
			assert_ne(mode.mode_name, forbidden)
	for forbidden in forbidden_names:
		assert_ne(view_model.promo_bundle_name, forbidden)

func test_lobby_mode_entry_stores_fields_correctly() -> void:
	var entry := LobbyModeEntry.new("Battle Royale", "Meridian", 4)
	assert_eq(entry.mode_name, "Battle Royale")
	assert_eq(entry.map_name, "Meridian")
	assert_eq(entry.squad_size, 4)
