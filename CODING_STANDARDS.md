# Project Warzone — Coding Standards

## General

- **No placeholder code.** If a script is committed, it compiles and
  does what its name says. TODOs are allowed only for *future phase*
  work explicitly out of scope, and must reference a milestone
  (`# TODO(Phase 7): attachment recoil modifiers`).
- Every public class/function has a doc comment describing purpose,
  parameters, and return value.
- Every feature folder has a `README.md` documented before or
  alongside its first script (architecture-first, per project rules).

## GDScript

- Godot 4 typed GDScript everywhere: `var health: int = 100`, typed
  function signatures, typed signal parameters.
- `class_name` on every reusable script; file name matches class name
  in snake_case (`weapon_stats.gd` → `class_name WeaponStats`).
- Signals for intra-feature communication; **Event Bus** singleton for
  cross-feature communication only.
- No `get_node("../../X")` traversal across feature boundaries —
  inject via `Services` container or `@export` reference within the
  same feature's scene.
- One class per file. No god-objects; a script over ~300 lines is a
  signal to split responsibilities.

## C# (performance-critical systems only)

Used for: physics-heavy systems, large-scale entity iteration (loot
spawns, projectile pools), and any system profiling shows GDScript is
a bottleneck for. Default to GDScript unless there's a measured reason
not to — do not pre-optimize into C#.

- Nullable reference types enabled.
- Namespacing: `RSGames.ProjectWarzone.<Feature>`.
- No static mutable state outside explicitly documented singletons.

## Server (Nakama modules)

- TypeScript preferred for match logic readability; Go reserved for
  modules where per-tick performance is measured to require it.
- Every RPC handler validates its input schema before touching game
  state — reject-by-default, not sanitize-and-continue.
- No RPC handler trusts a client-supplied position, damage value, or
  currency amount without server-side recomputation or bounds check.

## Commits

- Conventional commit style: `feat(weapons): add hitscan raycast core`,
  `docs(architecture): add networking model`, `fix(inventory): correct
  stack merge bug`.
- One logical change per commit; architecture/docs changes are
  committed separately from code.

## Testing

- Every feature ships with a `tests/` note in its README describing
  manual test steps until automated test harnesses exist (from Phase
  3 onward, unit tests are required for all `domain/` and
  `application/` layer code).

## Naming

- Original names only. No terms, weapon names, map names, or UI
  iconography copied from existing commercial titles.
