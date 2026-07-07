# Nakama Client Adapter

**Layer:** Infrastructure
**Status:** Implemented (Phase 4 HTTP/session API + Phase 5 realtime socket API + Phase 7 weapon fire/damage messages + Phase 8 inventory RPCs)

## Responsibility

Wraps the vendored Nakama Godot client SDK
(`client/addons/com.heroiclabs.nakama/`, v3.3.1-godot4): connection
setup, authenticate calls, RPC calls, and — as of Phase 5 — the
realtime WebSocket connection, match join/leave, and match state
send/receive. The only place in the client allowed to reference the
raw Nakama SDK types directly.

## Files

- `nakama_connection_config.gd` — local-dev connection constants
  (server key, host, port); see its docstring for the Phase 15
  TODO on making this environment-configurable
- `nakama_client_adapter.gd` — the adapter itself
- `auth_result.gd` — value object decoupling callers from raw
  `NakamaSession`/`NakamaException` SDK types

## Depends On

- `client/addons/com.heroiclabs.nakama` (vendored SDK, registered as
  the `Nakama` autoload in `project.godot`)
- `client/networking/replication/match_opcodes.gd` (shared opcode
  constants, manually kept in sync with the server — see that file)

## Public Interface

- `NakamaClientAdapter.authenticate_guest_async(device_id) -> AuthResult`
- `NakamaClientAdapter.authenticate_email_async(email, password, create_if_missing) -> AuthResult`
- `NakamaClientAdapter.authenticate_google_async(firebase_id_token) -> AuthResult`
- `NakamaClientAdapter.claim_nickname_async(nickname) -> Variant`
- `NakamaClientAdapter.create_match_for_testing_async() -> String` (TEMPORARY, see docstring)
- `NakamaClientAdapter.get_inventory_async() -> Variant`
- `NakamaClientAdapter.equip_item_async(item_id) -> Variant`
- `NakamaClientAdapter.purchase_item_async(item_id) -> Variant`
- `NakamaClientAdapter.connect_socket_async() -> bool`
- `NakamaClientAdapter.join_match_async(match_id) -> bool`
- `NakamaClientAdapter.send_player_input(position, delta_seconds) -> void`
- `NakamaClientAdapter.send_weapon_fire_claim(target_id, weapon_id, distance_meters) -> void`
- signals: `match_snapshot_received(snapshot)`, `position_corrected(position)`, `match_joined(match_id)`, `socket_connection_error(error)`, `damage_event_received(target_id, source_id, amount, remaining_health)`, `elimination_event_received(user_id)`

## Tests

Not yet unit-testable in true isolation (constructing the real adapter
requires the `Nakama` SDK autoload). `client/features/authentication`
tests it indirectly through `FakeNakamaClientAdapter` — see
`client/tests/unit/features/authentication/fixtures/`. The realtime
socket methods added in Phase 5 are reviewed against the vendored
SDK's actual method/return signatures (several return-type assumptions
were corrected during review — see PHASE_05 report) but not yet
covered by a fake/test double the way the HTTP API is.

## Notes

All feature services depend on this adapter's interface, never on the
raw Nakama SDK, so the SDK can be upgraded in isolation.

All RPC-calling methods (`claim_nickname_async`,
`create_match_for_testing_async`, the Phase 8 inventory methods) share
a private `_call_rpc_json()` helper for the common "call, check
exception, parse JSON" pattern — added in Phase 8 when a third
near-identical RPC method made the duplication worth removing.
