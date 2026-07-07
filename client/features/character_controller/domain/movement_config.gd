class_name MovementConfig
extends RefCounted
## Movement tuning constants. Single source of truth so
## `movement_calculator.gd` (client prediction) and any future
## server-side mirroring stay consistent — and so
## `server/modules/match_handler`'s `PLAYER_MAX_SPEED_METERS_PER_SECOND`
## anti-speed-hack bound has an obvious client-side counterpart to
## compare against (see that file's docstring for the manual-sync
## note; same caveat applies here).

const MAX_SPEED_METERS_PER_SECOND: float = 6.0
const ACCELERATION_METERS_PER_SECOND_SQUARED: float = 40.0
const DECELERATION_METERS_PER_SECOND_SQUARED: float = 50.0
const JUMP_VELOCITY_METERS_PER_SECOND: float = 4.5
const GRAVITY_METERS_PER_SECOND_SQUARED: float = 20.0

## Matches server/modules/match_handler's MATCH_TICK_RATE — see
## client/networking/replication/match_opcodes.gd for the same
## "manually synced with server" pattern.
const NETWORK_TICK_RATE: int = 10
