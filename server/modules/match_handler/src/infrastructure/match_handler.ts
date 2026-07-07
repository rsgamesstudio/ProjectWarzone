import { handlePlayerInput, type PlayerInputMessage } from "../application/handle_player_input";
import { buildSnapshot } from "../application/build_snapshot";
import { handleWeaponFire, type WeaponFireClaim } from "../application/handle_weapon_fire";
import { MatchOpcode } from "../domain/match_opcodes";
import { DEFAULT_MAX_PLAYERS, MATCH_TICK_RATE, MAX_HEALTH, type WarzoneMatchState, type PlayerMatchState } from "../domain/match_state";

export const MATCH_MODULE_NAME = "meridian_battle_royale";

/**
 * Implements Nakama's match handler contract
 * (matchInit/matchJoinAttempt/matchJoin/matchLeave/matchLoop/
 * matchTerminate/matchSignal). This is the "infrastructure" layer —
 * it translates between Nakama's runtime API and the pure
 * domain/application logic in `../domain` and `../application`.
 *
 * Registered under the name `MATCH_MODULE_NAME` via
 * `initializer.registerMatch` in `../index.ts`.
 */

function deriveSeedFromMatchId(matchId: string): number {
  // Simple deterministic string hash — doesn't need to be
  // cryptographically strong, just consistent per match ID so every
  // player's client computes the same zone.
  let hash = 0;
  for (let i = 0; i < matchId.length; i++) {
    hash = (hash * 31 + matchId.charCodeAt(i)) | 0;
  }
  return hash;
}

export const matchInit: nkruntime.MatchInitFunction<WarzoneMatchState> = function (
  ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _params: { [key: string]: any }
) {
  const state: WarzoneMatchState = {
    players: {},
    zoneSeed: deriveSeedFromMatchId(ctx.matchId ?? "0"),
    matchStartTick: 0,
    tickRate: MATCH_TICK_RATE,
  };

  return {
    state,
    tickRate: MATCH_TICK_RATE,
    label: MATCH_MODULE_NAME,
  };
};

export const matchJoinAttempt: nkruntime.MatchJoinAttemptFunction<WarzoneMatchState> = function (
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  state: WarzoneMatchState,
  _presence: nkruntime.Presence,
  _metadata: { [key: string]: any }
) {
  const currentPlayerCount = Object.keys(state.players).length;
  if (currentPlayerCount >= DEFAULT_MAX_PLAYERS) {
    return { state, accept: false, rejectMessage: "Match is full." };
  }
  return { state, accept: true };
};

export const matchJoin: nkruntime.MatchJoinFunction<WarzoneMatchState> = function (
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _dispatcher: nkruntime.MatchDispatcher,
  tick: number,
  state: WarzoneMatchState,
  presences: nkruntime.Presence[]
) {
  for (const presence of presences) {
    const player: PlayerMatchState = {
      userId: presence.userId,
      username: presence.username,
      position: { x: 0, y: 0, z: 0 },
      connected: true,
      lastUpdateTick: tick,
      health: MAX_HEALTH,
      eliminated: false,
      lastFireTickByWeapon: {},
    };
    state.players[presence.userId] = player;
  }
  return { state };
};

export const matchLeave: nkruntime.MatchLeaveFunction<WarzoneMatchState> = function (
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  state: WarzoneMatchState,
  presences: nkruntime.Presence[]
) {
  for (const presence of presences) {
    const player = state.players[presence.userId];
    if (player) {
      // Marked disconnected rather than deleted outright — keeps the
      // player's last-known position around in case of a Phase 5
      // reconnect-handling flow (this project's networking
      // requirements explicitly call for reliable reconnect
      // handling), without this module needing to know the details
      // of how reconnection is initiated.
      player.connected = false;
    }
  }
  return { state };
};

export const matchLoop: nkruntime.MatchLoopFunction<WarzoneMatchState> = function (
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher,
  tick: number,
  state: WarzoneMatchState,
  messages: nkruntime.MatchMessage[]
) {
  for (const message of messages) {
    if (message.opCode === MatchOpcode.PlayerInput) {
      const player = state.players[message.sender.userId];
      if (!player || !player.connected) {
        continue;
      }

      let parsed: PlayerInputMessage;
      try {
        parsed = JSON.parse(nk.binaryToString(message.data));
      } catch {
        continue; // malformed input message — ignore rather than crash the whole match loop
      }

      const deltaSeconds = (tick - player.lastUpdateTick) / state.tickRate;
      const result = handlePlayerInput(player, { position: parsed.position, deltaSeconds }, tick);
      state.players[message.sender.userId] = result.updatedPlayer;

      if (result.correction !== null) {
        dispatcher.broadcastMessage(
          MatchOpcode.PositionCorrection,
          JSON.stringify(result.correction),
          [message.sender],
          null,
          true
        );
      }
    } else if (message.opCode === MatchOpcode.WeaponFireClaim) {
      const shooter = state.players[message.sender.userId];
      if (!shooter || !shooter.connected || shooter.eliminated) {
        continue;
      }

      let claim: WeaponFireClaim;
      try {
        claim = JSON.parse(nk.binaryToString(message.data));
      } catch {
        continue; // malformed fire claim — ignore rather than crash the whole match loop
      }

      const target = state.players[claim.targetId];
      if (!target) {
        continue; // claims against a nonexistent target are simply dropped, not an error
      }

      const result = handleWeaponFire(shooter, target, claim, tick, state.tickRate);
      if (!result.accepted) {
        continue; // implausible claim — silently dropped; see ADR-0007
      }

      state.players[shooter.userId] = result.updatedShooter;
      state.players[claim.targetId] = result.updatedTarget;

      dispatcher.broadcastMessage(
        MatchOpcode.DamageEvent,
        JSON.stringify({
          targetId: claim.targetId,
          sourceId: shooter.userId,
          amount: result.damageDealt,
          remainingHealth: result.updatedTarget.health,
        }),
        null,
        null,
        true
      );

      if (result.targetEliminated) {
        dispatcher.broadcastMessage(
          MatchOpcode.EliminationEvent,
          JSON.stringify({ userId: claim.targetId }),
          null,
          null,
          true
        );
      }
    }
  }

  const snapshot = buildSnapshot(state, tick);
  dispatcher.broadcastMessage(MatchOpcode.Snapshot, JSON.stringify(snapshot), null, null, false);

  return { state };
};

export const matchTerminate: nkruntime.MatchTerminateFunction<WarzoneMatchState> = function (
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  state: WarzoneMatchState,
  _graceSeconds: number
) {
  return { state };
};

export const matchSignal: nkruntime.MatchSignalFunction<WarzoneMatchState> = function (
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  state: WarzoneMatchState,
  data: string
) {
  return { state, data };
};

export const matchHandler: nkruntime.MatchHandler<WarzoneMatchState> = {
  matchInit,
  matchJoinAttempt,
  matchJoin,
  matchLeave,
  matchLoop,
  matchTerminate,
  matchSignal,
};
