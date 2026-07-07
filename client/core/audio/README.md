# Audio (Music Playback)

**Layer:** Core infrastructure
**Status:** Implemented (Phase 7)

## Responsibility

Cross-cutting music playback — currently just the lobby theme, played
on login and looped through the lobby, paused during a match and
resumed on return (once Phase 11 wires the actual match-join/leave
trigger points — see Notes).

## Files

- `music_player.gd` — `MusicPlayer` (extends `AudioStreamPlayer`),
  registered into `Services` under `"MusicPlayer"` by `Bootstrap`.
  Unlike `EventBus`/`NakamaClientAdapter`, this must be an actual Node
  in the scene tree to play audio at all — `Bootstrap` adds it as a
  child of itself.
- `audio_tracks.gd` — `AudioTracks`, a central registry of track
  resource paths so `res://assets/audio/...` isn't hardcoded more than once

## Depends On

- `client/core/di` (registered via `Services`)
- `client/core/autoload` (constructed by `Bootstrap`)

## Public Interface

- `MusicPlayer.play_looped(stream: AudioStream)` — sets native
  seamless looping on `AudioStreamMP3`/`AudioStreamOggVorbis` resources
- `MusicPlayer.pause_for_match()`
- `MusicPlayer.resume_if_paused()` — safe no-op if nothing was paused

## Tests

Not unit tested — real audio playback requires the engine's audio
server, which isn't meaningfully mockable/testable the way pure logic
is. Reviewed structurally, not executed; see PHASE_07 report.

## Notes

`pause_for_match()`/`resume_if_paused()` exist and are correct, but
nothing calls `pause_for_match()` yet — there's no real match-join
flow to trigger it until Phase 11. `login_screen.gd` calls
`play_looped()`; `lobby_screen.gd` calls `resume_if_paused()` (a no-op
today, since nothing has paused it yet, but exactly the call Phase 11
needs when a player returns to the lobby after a match).

See `client/assets/README.md` for the current lobby theme's licensing
status (Suno-generated, commercial rights TBD).
