extends PanelContainer
## A single mode/map card in the lobby's mode-select list. Selecting it
## (clicking anywhere on the card) emits `selected` with no arguments —
## the parent lobby screen already knows which `LobbyModeEntry` this
## card was built from (see lobby_screen.gd's use of `.bind(mode)`),
## so this script only needs to report "I was clicked", not carry data
## itself.

signal selected

@onready var mode_name_label: Label = %ModeNameLabel
@onready var map_name_label: Label = %MapNameLabel
@onready var squad_size_label: Label = %SquadSizeLabel
@onready var click_button: Button = %ClickButton

func setup(mode: LobbyModeEntry) -> void:
	mode_name_label.text = mode.mode_name
	map_name_label.text = mode.map_name
	squad_size_label.text = "%d" % mode.squad_size

func _ready() -> void:
	click_button.pressed.connect(func() -> void: selected.emit())
