# Core Autoloads

**Layer:** Engine bootstrap
**Status:** Implemented (Phase 3)

## Responsibility

The minimal set of true Godot autoloads: `Services` (DI container,
script lives in `core/di/service_container.gd`) and `Bootstrap`
(startup sequencing, script lives in this folder). All other
cross-cutting systems register as services into `Services`, not as
additional autoloads — see ARCHITECTURE.md §5 for why.

## Depends On

- none (this is the root of the dependency graph)

## Public Interface

- autoload `Services` → `core/di/service_container.gd`
- autoload `Bootstrap` → `core/autoload/bootstrap.gd`

Registered in `client/project.godot` under `[autoload]`, in that
order — order matters, since `Bootstrap._ready()` registers services
into `Services` and relies on it already existing.

## Files

- `bootstrap.gd` — constructs and registers core, feature-agnostic
  services (EventBus, NakamaClientAdapter, MusicPlayer) at startup

## Tests

- `client/tests/integration/core/test_bootstrap_integration.gd`
  verifies the real autoload chain: `Bootstrap` ran, its core services are
  registered, and repeated resolution returns the same singleton
  instance.

## Notes

Kept deliberately tiny. Do not add feature-specific initialization to
`bootstrap.gd` — if a feature needs startup logic, it belongs in that
feature's own composition root, not here.
