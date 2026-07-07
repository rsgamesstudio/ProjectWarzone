# Server Module Tests

**Layer:** Testing
**Status:** Not implemented (scheduled: Phase 5+)

## Responsibility

Tests for Nakama module RPC handlers, validation logic, and match simulation determinism.

## Depends On

- local Docker stack (`infra/docker`)

## Public Interface (planned)

- test files mirror `server/modules/` structure

## Notes

Anti-cheat and economy-affecting RPCs require test coverage before being considered complete.
