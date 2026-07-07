# Voice Chat

**Layer:** Client feature module
**Status:** Not implemented (scheduled: Phase 12)

## Responsibility

Real-time proximity and squad voice channels, mute/block/report controls, bandwidth-aware codec/quality selection.

## Depends On

- `client/networking/nakama_client` (signaling)
- `client/core/di`

## Public Interface (planned)

- `VoiceChatService.set_channel(PROXIMITY | SQUAD)`
- `VoiceChatService.mute(player_id)`
- `VoiceChatService.report(player_id, reason)`

## Notes

Transport (WebRTC via relay vs SFU) decided by ADR at start of Phase 12.
