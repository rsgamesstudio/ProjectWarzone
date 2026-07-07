extends Control
## Studio splash screen: fades in the RS GAMES crest, holds, fades out,
## then emits `finished`. Presentation-layer only — this scene knows
## nothing about what comes next; `ui_root.gd` decides that.
##
## Uses the studio's actual crest image at
## client/assets/textures/branding/rs_games_logo.png — this is the
## studio's own original branding, not a copied third-party asset.

signal finished

const FADE_IN_SECONDS: float = 0.6
const HOLD_SECONDS: float = 1.2
const FADE_OUT_SECONDS: float = 0.5

@onready var logo: TextureRect = %Logo
@onready var studio_label: Label = %StudioLabel

var _has_finished: bool = false

func _ready() -> void:
	logo.modulate.a = 0.0
	studio_label.modulate.a = 0.0
	_play_sequence()

func _play_sequence() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(logo, "modulate:a", 1.0, FADE_IN_SECONDS)
	tween.tween_property(studio_label, "modulate:a", 1.0, FADE_IN_SECONDS).set_delay(0.2)
	tween.set_parallel(false)
	tween.tween_interval(HOLD_SECONDS)
	tween.set_parallel(true)
	tween.tween_property(logo, "modulate:a", 0.0, FADE_OUT_SECONDS)
	tween.tween_property(studio_label, "modulate:a", 0.0, FADE_OUT_SECONDS)
	tween.set_parallel(false)
	tween.finished.connect(_emit_finished_once)

## Allows a player to skip the splash with any input, rather than
## forcing them to sit through it every single launch.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.is_pressed():
			get_viewport().set_input_as_handled()
			_emit_finished_once()

func _emit_finished_once() -> void:
	if _has_finished:
		return
	_has_finished = true
	finished.emit()
