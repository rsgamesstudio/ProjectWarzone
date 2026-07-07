# Vendored Dependency: Nakama Runtime Type Definitions

- Source: https://github.com/heroiclabs/nakama-common (`index.d.ts`)
- License: Apache-2.0 (see LICENSE in this folder)

These are Heroic Labs' official ambient TypeScript type definitions
for the Nakama server runtime (the `nkruntime` global namespace —
`nkruntime.Nakama`, `nkruntime.Context`, `nkruntime.Initializer`,
etc.). They are NOT an importable ES module/npm package in normal
use — Nakama's own project template consumes them the same way, by
including the `.d.ts` file directly in the TypeScript compilation
(see `../tsconfig.json`) rather than via `import`. Do not add an
`import`/`require` for these types anywhere; reference `nkruntime.X`
directly as an ambient global type.

Vendored directly (same rationale as `client/addons/gut/VENDORED.md`)
so the module compiles immediately with no extra setup step. Update by
re-vendoring `index.d.ts` from a newer commit if Nakama's runtime API
changes.
