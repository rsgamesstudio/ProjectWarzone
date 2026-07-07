class_name WeaponController
extends RefCounted
## Local ammo/fire-rate/reload state machine for one equipped weapon.
## Pure logic — no scene-tree/engine dependency beyond the
## `WeaponDefinitions` data, fully unit-testable. The presentation
## layer (a future weapon-holding scene, not yet built — see this
## feature's README) calls `try_fire()`/`start_reload()`/`tick()` and
## handles the actual raycast/visual/network-send side effects itself.
##
## This is CLIENT-SIDE PREDICTION for responsive UX (can't fire while
## reloading, ammo counter, etc.) — the server independently tracks
## its own fire-rate cooldown per ADR-0007 and is what actually
## decides whether a hit counts. A desync between this and the
## server's cooldown tracking only affects local UX smoothness, never
## actual damage authority.

var weapon: WeaponDefinitions.WeaponDefinition
var current_ammo: int
var is_reloading: bool = false
var _reload_time_remaining: float = 0.0
var _cooldown_remaining: float = 0.0

func _init(p_weapon: WeaponDefinitions.WeaponDefinition) -> void:
	weapon = p_weapon
	current_ammo = p_weapon.magazine_size

## Returns true and consumes one round if firing is currently allowed
## (not reloading, has ammo, fire-rate cooldown elapsed). Returns false
## and consumes nothing otherwise — the caller should not raycast or
## send a network message on a false return.
func try_fire() -> bool:
	if is_reloading:
		return false
	if current_ammo <= 0:
		return false
	if _cooldown_remaining > 0.0:
		return false

	current_ammo -= 1
	_cooldown_remaining = 1.0 / weapon.fire_rate_per_second
	return true

## Starts a reload if not already reloading and not already at a full
## magazine. Safe to call redundantly (no-op if already reloading or full).
func start_reload() -> void:
	if is_reloading or current_ammo == weapon.magazine_size:
		return
	is_reloading = true
	_reload_time_remaining = weapon.reload_seconds

## Call once per frame/tick with elapsed time to advance cooldown and
## reload timers.
func tick(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = max(0.0, _cooldown_remaining - delta)

	if is_reloading:
		_reload_time_remaining -= delta
		if _reload_time_remaining <= 0.0:
			is_reloading = false
			current_ammo = weapon.magazine_size

func can_fire() -> bool:
	return not is_reloading and current_ammo > 0 and _cooldown_remaining <= 0.0

func reload_progress() -> float:
	if not is_reloading or weapon.reload_seconds <= 0.0:
		return 0.0
	return 1.0 - (_reload_time_remaining / weapon.reload_seconds)
