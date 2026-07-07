extends Control
## Lobby screen prototype. Renders a `LobbyViewModel` from
## `MockLobbyDataProvider` — see that class for exactly what's mocked
## and what will replace it (Phases 8/9/11).
##
## Layout matches the general structure of a typical mobile BR lobby
## (currency bar, promo banner, event panels, mode-select, world chat)
## with entirely original naming — see ADR-0005 and its addendum for
## why "Fortune Cache", "Nightfall Bundle", "Founders Cup", and
## "Season Path" replace the reference image's branded/trademarked
## equivalents.
##
## Buttons that don't have a real feature behind them yet (Loadout,
## Clan, Leaderboard, Store, Fortune Cache, Missions, Events, Start)
## are wired to `_on_not_yet_implemented` rather than left disconnected
## or faked into pretending to work — clicking them logs which future
## phase implements them, which is more honest than either a silent
## no-op or a fake success state.

@onready var player_name_label: Label = %PlayerNameLabel
@onready var player_level_label: Label = %PlayerLevelLabel
@onready var vip_label: Label = %VipLabel
@onready var credits_label: Label = %CreditsLabel
@onready var marks_label: Label = %MarksLabel
@onready var promo_bundle_label: Label = %PromoBundleLabel
@onready var season_path_level_label: Label = %SeasonPathLevelLabel
@onready var season_path_progress_bar: ProgressBar = %SeasonPathProgressBar
@onready var founders_cup_label: Label = %FoundersCupLabel
@onready var world_chat_label: Label = %WorldChatLabel
@onready var mode_list_container: VBoxContainer = %ModeListContainer
@onready var start_button: Button = %StartButton
@onready var loadout_button: Button = %LoadoutButton
@onready var clan_button: Button = %ClanButton
@onready var leaderboard_button: Button = %LeaderboardButton
@onready var store_button: Button = %StoreButton
@onready var fortune_cache_button: Button = %FortuneCacheButton
@onready var character_button: Button = %CharacterButton
@onready var missions_button: Button = %MissionsButton
@onready var events_button: Button = %EventsButton
@onready var friends_button: Button = %FriendsButton

const MODE_CARD_SCENE_PATH: String = "res://features/lobby/presentation/mode_card.tscn"

var _data_provider := MockLobbyDataProvider.new()
var _selected_mode: LobbyModeEntry = null

func _ready() -> void:
	var view_model: LobbyViewModel = _data_provider.get_view_model()
	_render(view_model)

	# Resumes the lobby theme if it was paused for a match — a no-op
	# the first time the lobby is shown (right after login), since
	# nothing has paused it yet. See MusicPlayer's docstring.
	var music_player: MusicPlayer = Services.resolve("MusicPlayer")
	music_player.resume_if_paused()

	# TODO(Phase 11): once real matchmaking exists, call
	# Services.resolve("MusicPlayer").pause_for_match() here (or
	# wherever the actual match-join transition happens) before
	# leaving the lobby scene — not wired yet since Start doesn't
	# actually enter a match today, only logs "not implemented".
	start_button.pressed.connect(func() -> void: _on_not_yet_implemented("Matchmaking (Phase 11)"))
	loadout_button.pressed.connect(func() -> void: _on_not_yet_implemented("Inventory/Loadout (Phase 8)"))
	clan_button.pressed.connect(func() -> void: _on_not_yet_implemented("Clan/Squad system"))
	leaderboard_button.pressed.connect(func() -> void: _on_not_yet_implemented("Leaderboards (Phase 9)"))
	store_button.pressed.connect(func() -> void: _on_not_yet_implemented("Cosmetics store (Phase 8)"))
	fortune_cache_button.pressed.connect(func() -> void: _on_not_yet_implemented("Fortune Cache (gacha-style feature, not yet scoped to a phase)"))
	character_button.pressed.connect(func() -> void: _on_not_yet_implemented("Character customization (Phase 8)"))
	missions_button.pressed.connect(func() -> void: _on_not_yet_implemented("Daily/weekly missions (Phase 9)"))
	events_button.pressed.connect(func() -> void: _on_not_yet_implemented("Event Center (not yet scoped to a phase)"))
	friends_button.pressed.connect(func() -> void: _on_not_yet_implemented("Friend system"))

func _render(view_model: LobbyViewModel) -> void:
	player_name_label.text = view_model.player_name
	player_level_label.text = "LEVEL %d" % view_model.player_level
	vip_label.text = "VIP %d" % view_model.vip_tier
	credits_label.text = "%s" % _format_number(view_model.credits)
	marks_label.text = "%s" % _format_number(view_model.marks)
	promo_bundle_label.text = view_model.promo_bundle_name
	season_path_level_label.text = "%d  SEASON PATH" % view_model.season_path_level
	season_path_progress_bar.value = view_model.season_path_progress * 100.0
	founders_cup_label.text = "FOUNDERS CUP" + (" — LIVE NOW" if view_model.founders_cup_live else "")
	world_chat_label.text = view_model.world_chat_message

	for child in mode_list_container.get_children():
		child.queue_free()

	var mode_card_scene: PackedScene = load(MODE_CARD_SCENE_PATH)
	for mode: LobbyModeEntry in view_model.modes:
		var card := mode_card_scene.instantiate()
		mode_list_container.add_child(card)
		card.setup(mode)
		card.selected.connect(_on_mode_selected.bind(mode))

	if not view_model.modes.is_empty():
		_selected_mode = view_model.modes[0]

func _on_mode_selected(mode: LobbyModeEntry) -> void:
	_selected_mode = mode

func _on_not_yet_implemented(feature_description: String) -> void:
	print("[Lobby] Not implemented yet: %s." % feature_description)

func _format_number(value: int) -> String:
	var s := str(value)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i != 0:
			result = "," + result
	return result
