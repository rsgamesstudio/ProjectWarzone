# Vendored Dependency: Nakama Godot Client SDK

- Source: https://github.com/heroiclabs/nakama-godot
- Version: v3.3.1-godot4
- License: Apache-2.0 (see LICENSE in this folder)

The official client SDK for talking to a Nakama server from Godot.
Provides `NakamaClient` (HTTP/session API — used from Phase 4 onward
for authentication) and `NakamaSocket` (realtime WebSocket API — used
starting Phase 5 for match communication).

Requires registering `Nakama.gd` (this folder's root script) as an
autoload named exactly `Nakama` in project.godot — done as part of
Phase 4. Our own `client/networking/nakama_client/` adapter wraps this
SDK rather than letting features call it directly, so the SDK version
can be upgraded in one place (see that folder's README).

Vendored directly rather than as a submodule, consistent with
`client/addons/gut/VENDORED.md`.
