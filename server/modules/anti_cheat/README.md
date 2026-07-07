# Anti-Cheat Module

**Layer:** Nakama server module
**Status:** Not implemented (scheduled: Phase 5 (foundation) / ongoing)

## Responsibility

Server-side validation framework: movement speed bounds, RPC rate limiting, input schema validation, anomaly flagging feeding the report/ban system.

## Depends On

- `server/modules/match_handler`
- PostgreSQL (flags/bans)

## Public Interface (planned)

- internal `validate_movement(delta, dt)`
- internal `rate_limit(rpc_id, session)`

## Notes

Foundation (rate limiting, schema validation) lands in Phase 5; heuristic/statistical cheat detection expands over time per project rules (never skip security review).
