import type { WarzoneMatchState } from "../domain/match_state";
import { getZoneStateAtElapsedSeconds } from "../domain/safe_zone_schedule";

export interface SnapshotPayload {
  serverTick: number;
  elapsedSeconds: number;
  players: { userId: string; position: { x: number; y: number; z: number } }[];
  zone: {
    center: { x: number; y: number; z: number };
    radiusMeters: number;
    nextShrinkAtSeconds: number | null;
  };
}

/**
 * Builds the compact snapshot broadcast to every client each tick.
 * Pure function of the current state — no Nakama API calls, no
 * mutation, fully testable.
 */
export function buildSnapshot(state: WarzoneMatchState, currentTick: number): SnapshotPayload {
  const elapsedSeconds = (currentTick - state.matchStartTick) / state.tickRate;
  const zone = getZoneStateAtElapsedSeconds(elapsedSeconds, state.zoneSeed);

  return {
    serverTick: currentTick,
    elapsedSeconds,
    players: Object.values(state.players)
      .filter((p) => p.connected)
      .map((p) => ({ userId: p.userId, position: p.position })),
    zone: {
      center: zone.center,
      radiusMeters: zone.radiusMeters,
      nextShrinkAtSeconds: zone.nextShrinkAtSeconds,
    },
  };
}
