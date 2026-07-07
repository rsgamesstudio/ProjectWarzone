# Server Reconciliation

**Layer:** Infrastructure
**Status:** Implemented (Phase 5)

## Responsibility

Compares the locally predicted position at a given tick against the
server's authoritative snapshot for that tick, decides whether the
divergence warrants a correction, and replays buffered inputs after a
correction so the corrected present-moment position is recomputed
immediately rather than rolling back visibly.

## Files

- `reconciler.gd` — `Reconciler` (static methods) + `ReconciliationResult`

## Depends On

- `client/networking/prediction` (consumes `PredictionBuffer.Entry` objects during replay)

## Public Interface

- `Reconciler.reconcile(predicted_position, server_position) -> ReconciliationResult`
- `Reconciler.replay(corrected_position, entries_to_replay) -> Vector3`
- `Reconciler.CORRECTION_THRESHOLD_METERS` (currently 0.15m)

## Tests

- `client/tests/unit/networking/reconciliation/test_reconciler.gd` (6 cases)

## Notes

Small divergence (network jitter, float drift) is deliberately ignored
below the threshold to avoid visibly "snapping" the player for no
reason. The threshold is a tunable, not a hardcoded law — expect it to
move once real playtesting (Phase 14) shows whether 15cm feels right.
