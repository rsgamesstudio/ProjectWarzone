# ADR-0006: Match Handler Language — TypeScript for Now, Go on a Documented Trigger

**Status:** Accepted
**Date:** 2026-07-04

## Context

ARCHITECTURE.md §9 deliberately deferred this decision to Phase 5:
"Exact Nakama match handler language (Go vs. TypeScript) — decided in
Phase 5 with a benchmarked ADR." CODING_STANDARDS.md already sets the
general default: TypeScript unless profiling shows a measured need for
Go's performance.

A real benchmark requires a running match handler under realistic
50-player tick load — which doesn't exist yet (this phase is what
creates it). So this ADR makes the initial call on architectural
reasoning, and defines the concrete trigger for revisiting it with a
real benchmark once one is possible.

## Decision

**Start with TypeScript**, same as every other server module so far.

Reasoning:
- Nakama's TS runtime executes in `goja`, a pure-Go JS interpreter
  with no JIT. Per-tick work here (reading input, updating ~50 player
  positions, safe-zone math, broadcasting snapshots) is real but not
  enormous — comparable work already runs fine in TS in production
  Nakama deployments at moderate tick rates.
- Go requires compiling a native plugin (`--buildmode=plugin`) that
  must match Nakama's exact Go toolchain version, normally built
  inside Heroic Labs' own builder Docker image. That's real
  operational overhead this project doesn't need to take on before
  there's evidence it's necessary — and this sandbox has no Go
  toolchain to verify such a build anyway, so shipping one now would
  mean shipping unverified code, which this project avoids (see every
  prior phase's testing discipline).
- Keeping the match handler in the same language as the rest of the
  server modules keeps the codebase's cognitive overhead lower while
  the team is still small.

**Concrete trigger to revisit:** once Phase 14 (Testing) load-tests a
real 50-player match and either (a) server tick time regularly exceeds
budget, or (b) CPU profiling shows the match loop itself (not I/O) as
the bottleneck, migrate the match handler specifically to Go. The
match handler's interface (`match_init`/`match_join`/`match_loop`/etc.)
is the same regardless of language, so this is a swap, not a rewrite
of anything that calls into it.

## Consequences

- `server/modules/match_handler/` is TypeScript, structured with the
  same domain/application/infrastructure layering as
  `server/modules/authentication/`.
- The tick rate chosen for Phase 5 (see that module's README) is
  deliberately conservative for the same reason — easy to raise later
  once real measurements exist.
