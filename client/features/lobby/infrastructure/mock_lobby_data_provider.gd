class_name MockLobbyDataProvider
extends RefCounted
## TEMPORARY data source for the lobby UI prototype (built early, at
## explicit request, ahead of its scheduled phases — see
## docs/phases/PHASE_04_AUTHENTICATION.md). Returns realistic-looking
## but entirely fabricated data so the lobby screen has something to
## render before the real dependencies exist:
##
##   - player_name/level  -> will come from AuthService (Phase 4/9) +
##                            a future player-profile/stats module
##   - credits/marks      -> will come from Phase 8 (Inventory) /
##                            an economy module
##   - modes              -> will come from Phase 11 (Matchmaking),
##                            reading real available mode/map data
##
## This class exists so that replacement is a one-line swap at the
## lobby screen's composition root (construct a different provider
## implementing the same `get_view_model()` shape) rather than a
## rewrite of the presentation script.

func get_view_model() -> LobbyViewModel:
	var modes: Array[LobbyModeEntry] = [
		LobbyModeEntry.new("Battle Royale", "Meridian", 4),
		LobbyModeEntry.new("Skirmish", "Meridian", 6),
	]
	return LobbyViewModel.new(
		"RS_GAMER", 45, 125500, 2350, modes,
		3, # vip_tier
		"Nightfall Bundle", # promo_bundle_name — original, replaces reference image's "Shadow Strike"
		27, 0.64, # season_path_level, season_path_progress — "Season Path" replaces "Battle Pass" (see ADR-0005 addendum)
		true, # founders_cup_live — original event name, replaces reference image's "Warzone Championship"
		"[World] RS_DARK: Let's go for the win!"
	)
