# CI/CD

**Layer:** DevOps
**Status:** Not implemented (scheduled: Phase 2/ongoing)

## Responsibility

Build/lint/test pipelines for client and server; later, deployment pipelines for staging/prod Nakama clusters.

## Depends On

- `infra/docker`

## Public Interface (planned)

- pipeline configs (GitHub Actions, added Phase 2)

## Notes

Starts as lint+build only; test gating added as automated test suites come online per phase.
