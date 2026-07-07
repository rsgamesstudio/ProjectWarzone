import { validateMovement, type Vector3 } from "../domain/movement_validation";
import type { PlayerMatchState } from "../domain/match_state";

export const PLAYER_MAX_SPEED_METERS_PER_SECOND = 6.0;

export interface PlayerInputMessage {
  position: Vector3;
  deltaSeconds: number;
}

export interface HandlePlayerInputResult {
  updatedPlayer: PlayerMatchState;
  /** Present only when the server had to correct the client's claimed position. */
  correction: Vector3 | null;
}

/**
 * Validates and applies one player's input message against their
 * current authoritative state. Pure orchestration over
 * `validateMovement` — no Nakama API calls here, so this is testable
 * without a mock `nk`.
 */
export function handlePlayerInput(
  player: PlayerMatchState,
  input: PlayerInputMessage,
  currentTick: number
): HandlePlayerInputResult {
  const result = validateMovement(
    player.position,
    input.position,
    input.deltaSeconds,
    PLAYER_MAX_SPEED_METERS_PER_SECOND
  );

  const updatedPlayer: PlayerMatchState = {
    ...player,
    position: result.resultingPosition,
    lastUpdateTick: currentTick,
  };

  return {
    updatedPlayer,
    correction: result.wasCorrected ? result.resultingPosition : null,
  };
}
