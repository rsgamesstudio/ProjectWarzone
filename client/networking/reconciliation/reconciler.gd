class_name Reconciler
extends RefCounted
## Compares the locally predicted position at a given tick against the
## server's authoritative snapshot for that same tick, and decides
## whether a correction is needed. Pure logic — no engine/network
## dependency, fully unit-testable.
##
## Correction policy: small divergence (network jitter, floating point
## drift) is ignored to avoid visibly "snapping" the player for no
## reason; divergence beyond `CORRECTION_THRESHOLD_METERS` snaps
## immediately to the server position, since letting genuinely wrong
## predicted state persist is worse than a rare visible correction.

## Below this distance, divergence is treated as noise and ignored.
const CORRECTION_THRESHOLD_METERS: float = 0.15

class ReconciliationResult:
	var needs_correction: bool
	var corrected_position: Vector3
	var divergence_meters: float

	func _init(p_needs_correction: bool, p_corrected_position: Vector3, p_divergence_meters: float) -> void:
		needs_correction = p_needs_correction
		corrected_position = p_corrected_position
		divergence_meters = p_divergence_meters

## @param predicted_position What the client's own prediction said the
##   position was at the snapshot's tick (looked up from
##   PredictionBuffer by the caller).
## @param server_position The authoritative position from the server's
##   snapshot at that same tick.
static func reconcile(predicted_position: Vector3, server_position: Vector3) -> ReconciliationResult:
	var divergence: float = predicted_position.distance_to(server_position)

	if divergence <= CORRECTION_THRESHOLD_METERS:
		return ReconciliationResult.new(false, predicted_position, divergence)

	return ReconciliationResult.new(true, server_position, divergence)

## Given a correction and the buffered inputs that happened AFTER the
## corrected tick, replays them starting from the corrected position
## to compute where the player should actually be right now. This is
## what makes correction feel instantaneous rather than like a
## rollback — only the historical predicted positions were wrong; the
## corrected present-moment position is recomputed immediately.
##
## `entries_to_replay` must be in chronological order (as returned by
## `PredictionBuffer.get_entries_after`).
static func replay(corrected_position: Vector3, entries_to_replay: Array) -> Vector3:
	var position := corrected_position
	for entry in entries_to_replay:
		position += entry.input_delta
	return position
