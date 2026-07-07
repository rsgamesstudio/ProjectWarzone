# Entity Replication

**Layer:** Infrastructure
**Status:** Implemented (Phase 5) — data pipeline only; actual remote
character rendering is Phase 6 (character_controller).

## Responsibility

Interpolates and provides positions for remote entities (players
today; vehicles/projectiles once those features exist) between
authoritative server snapshots, and routes incoming snapshot data from
`NakamaClientAdapter` to the right per-entity buffer.

## Files

- `interpolation_buffer.gd` — per-entity snapshot buffer + interpolation math
- `replication_manager.gd` — owns one `InterpolationBuffer` per remote user ID
- `match_opcodes.gd` — wire-protocol opcode constants (manually kept in sync with the server — see that file's docstring)

## Depends On

- `client/networking/nakama_client` (consumes `match_snapshot_received` payloads)

## Public Interface

- `ReplicationManager.ingest_snapshot(snapshot, local_user_id)`
- `ReplicationManager.get_interpolated_position(user_id, render_time_seconds) -> Vector3`
- `ReplicationManager.remove_entity(user_id)`
- `InterpolationBuffer.add_snapshot(timestamp_seconds, position)`
- `InterpolationBuffer.get_interpolated_position(render_time_seconds) -> Vector3`
- `InterpolationBuffer.interpolation_delay_seconds` (tunable per entity type)

## Tests

- `client/tests/unit/networking/replication/test_interpolation_buffer.gd` (8 cases)
- `client/tests/unit/networking/replication/test_replication_manager.gd` (5 cases)

## Notes

Interpolation buffer size/delay is one of the first tunables exposed
in Phase 13 (Optimization) for low-end devices. `ReplicationManager`
is deliberately NOT registered as a global `Services` singleton — its
lifecycle is tied to being in a match, so Phase 6's character
controller feature is expected to construct one on match join and
discard it on match leave, not hold one for the whole app lifetime.
