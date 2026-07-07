class_name LobbyViewModel
extends RefCounted
## Pure data the lobby screen renders. Deliberately has no knowledge of
## where its data came from (mock provider today; real
## AuthService/InventoryService/MatchmakingService lookups once Phases
## 8/9/11 land) — see infrastructure/mock_lobby_data_provider.gd for
## today's source and its documented replacement plan.

var player_name: String
var player_level: int
var vip_tier: int
var credits: int
var marks: int
var modes: Array[LobbyModeEntry]
var promo_bundle_name: String
var season_path_level: int
var season_path_progress: float # 0.0-1.0
var founders_cup_live: bool
var world_chat_message: String

func _init(
	p_player_name: String,
	p_player_level: int,
	p_credits: int,
	p_marks: int,
	p_modes: Array[LobbyModeEntry],
	p_vip_tier: int = 0,
	p_promo_bundle_name: String = "",
	p_season_path_level: int = 0,
	p_season_path_progress: float = 0.0,
	p_founders_cup_live: bool = false,
	p_world_chat_message: String = ""
) -> void:
	player_name = p_player_name
	player_level = p_player_level
	credits = p_credits
	marks = p_marks
	modes = p_modes
	vip_tier = p_vip_tier
	promo_bundle_name = p_promo_bundle_name
	season_path_level = p_season_path_level
	season_path_progress = p_season_path_progress
	founders_cup_live = p_founders_cup_live
	world_chat_message = p_world_chat_message
