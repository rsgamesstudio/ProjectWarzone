# Client-Side Prediction

**Layer:** Infrastructure
**Status:** Implemented (Phase 5)

## Responsibility

Records the local player's predicted position at each simulation
tick, so `reconciliation/` can later replay unacknowledged input once
a server snapshot arrives. Pure data structure — no engine/network
dependency.

## Files

- `prediction_buffer.gd` — `PredictionBuffer` + its inner `Entry` class

## Depends On

- none (deliberately dependency-free; `client/features/character_controller`
  in Phase 6 is what actually calls this from the scene tree)

## Public Interface

- `PredictionBuffer.record(tick, position, input_delta)`
- `PredictionBuffer.get_entry(tick) -> Entry`
- `PredictionBuffer.get_entries_after(after_tick) -> Array[Entry]`
- `PredictionBuffer.discard_up_to(tick)`

## Tests

- `client/tests/unit/networking/prediction/test_prediction_buffer.gd` (7 cases, including a max-history eviction test)

## Notes

Paired with `reconciliation/`; never used for anything that affects
other players' authoritative state — the server's snapshot always
wins on divergence (see `reconciliation/reconciler.gd`).
