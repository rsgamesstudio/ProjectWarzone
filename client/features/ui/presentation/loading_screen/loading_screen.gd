extends Control
## Loading screen shown between the splash and the lobby. Displays a
## progress bar and rotating tip text, then emits `finished`.
##
## IMPORTANT: progress here is SIMULATED — there is no real asset
## streaming/background-loading system wired up yet (that belongs to
## Phase 13, Optimization, per ARCHITECTURE.md). This scene is honest
## about that in its own code rather than pretending to track real
## load progress. When real background loading exists, replace
## `_simulate_progress()` with actual progress reporting from whatever
## loads next (e.g. ResourceLoader's threaded load status), without
## needing to change how this scene presents progress/tips.

signal finished

const SIMULATED_DURATION_SECONDS: float = 2.5
const TIP_ROTATION_INTERVAL_SECONDS: float = 1.8

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var percent_label: Label = %PercentLabel
@onready var tip_label: Label = %TipLabel
@onready var tip_timer: Timer = %TipTimer

var _tips_provider := LoadingTipsProvider.new()
var _elapsed: float = 0.0
var _has_finished: bool = false

func _ready() -> void:
	progress_bar.value = 0.0
	tip_label.text = _tips_provider.current()
	tip_timer.wait_time = TIP_ROTATION_INTERVAL_SECONDS
	tip_timer.timeout.connect(_on_tip_timer_timeout)
	tip_timer.start()

func _process(delta: float) -> void:
	if _has_finished:
		return
	_elapsed += delta
	var fraction: float = clamp(_elapsed / SIMULATED_DURATION_SECONDS, 0.0, 1.0)
	progress_bar.value = fraction * 100.0
	percent_label.text = "%d%%" % int(fraction * 100.0)

	if fraction >= 1.0:
		_has_finished = true
		tip_timer.stop()
		finished.emit()

func _on_tip_timer_timeout() -> void:
	tip_label.text = _tips_provider.next()
