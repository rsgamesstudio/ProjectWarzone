class_name LobbyModeEntry
extends RefCounted
## A single mode/map card shown in the lobby's mode-select list.
## Original names only — see ADR-0005 ("Meridian", "Skirmish", etc.).

var mode_name: String
var map_name: String
var squad_size: int

func _init(p_mode_name: String, p_map_name: String, p_squad_size: int) -> void:
	mode_name = p_mode_name
	map_name = p_map_name
	squad_size = p_squad_size
