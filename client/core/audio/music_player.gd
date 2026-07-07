class_name MusicPlayer
extends AudioStreamPlayer
## Cross-cutting music playback service, registered into Services
## under "MusicPlayer" by Bootstrap (must be an actual Node — and
## therefore in the scene tree — to play audio at all, unlike
## EventBus/NakamaClientAdapter which are plain RefCounted objects).
##
## Usage pattern for the login -> lobby -> match -> lobby flow:
##   - login_screen.gd calls play_looped() on _ready()
##   - lobby_screen.gd calls resume_if_paused() on _ready() — a no-op
##     the first time (already playing from login), and an actual
##     resume when returning from a match
##   - Once Phase 11 (Matchmaking) has a real match-join/match-end
##     flow, it should call pause_for_match() on join and
##     resume_if_paused() on returning to the lobby. That wiring
##     doesn't exist yet since there's no real match flow to hook into
##     — see this file's README note.

func play_looped(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	self.stream = stream
	play()

## Call when the player enters a match — music should not play during
## gameplay. Pauses rather than stops, so resume_if_paused() continues
## from the same point rather than restarting the track.
func pause_for_match() -> void:
	stream_paused = true

## Call when returning to the lobby after a match. Safe to call even
## if nothing was paused (e.g. the very first time entering the lobby
## right after login) — it's simply a no-op in that case.
func resume_if_paused() -> void:
	if stream_paused:
		stream_paused = false
