class_name ServerTickEstimator
extends RefCounted
## The server tags every snapshot with its own authoritative tick
## number, but the client needs to know "what tick is it right now" to
## tag ITS OWN predictions before the next snapshot arrives — that's
## what this class estimates.
##
## Approach: resync to the server's exact tick whenever a snapshot
## arrives, then extrapolate locally between snapshots based on
## elapsed time and the known tick rate. This does not compensate for
## clock drift/latency beyond that periodic resync — good enough for
## an initial implementation; a proper NTP-style clock sync is a
## documented candidate for later refinement (see this feature's
## README) if reconciliation proves too jittery in practice.

var _last_known_server_tick: int = 0
var _seconds_since_last_sync: float = 0.0
var _tick_rate: int

func _init(tick_rate: int = MovementConfig.NETWORK_TICK_RATE) -> void:
	_tick_rate = tick_rate

## Call whenever a new snapshot arrives, to resync the estimate to the
## server's ground truth and prevent local estimation error from
## accumulating indefinitely.
func resync(authoritative_tick: int) -> void:
	_last_known_server_tick = authoritative_tick
	_seconds_since_last_sync = 0.0

## Call once per local physics frame with that frame's delta time.
func advance(delta_seconds: float) -> void:
	_seconds_since_last_sync += delta_seconds

## Returns the best current estimate of the server's tick counter.
func estimate_current_tick() -> int:
	return _last_known_server_tick + int(_seconds_since_last_sync * _tick_rate)
