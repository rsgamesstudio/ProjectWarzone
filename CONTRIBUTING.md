# Contributing to Project Warzone

## Workflow

This project is built in strict phases (see `docs/milestones/MILESTONES.md`).
Do not implement a feature ahead of its phase — architecture and
documentation come first, always.

## Branch Strategy (effective Phase 2)

- `main` — always buildable, represents latest completed phase work
- `phase/<n>-<short-name>` — active phase development
- `feature/<feature-name>` — individual feature work merged into the phase branch

## Before Opening a PR

1. Confirm the change matches `CODING_STANDARDS.md`.
2. Confirm the relevant feature `README.md` is updated if the public
   interface changed.
3. Confirm the testing checklist for the affected phase (in
   `docs/phases/`) passes.

## Commit Style

See `CODING_STANDARDS.md` → Commits.
