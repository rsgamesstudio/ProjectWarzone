# Integration Tests

**Layer:** Testing
**Status:** Not implemented (scheduled: Phase 5+)

## Responsibility

Tests spanning client-server boundaries: auth flow, matchmaking flow, RPC contract validation.

## Depends On

- local Docker stack (`infra/docker`)

## Public Interface (planned)

- test files added as networked features land

## Notes

Run against the local Nakama/Postgres/Redis stack, never against production.
