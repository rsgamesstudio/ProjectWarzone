/**
 * Match message opcodes. These numbers are part of the wire protocol
 * between this server module and the client — they MUST stay in sync
 * with `client/networking/replication/match_opcodes.gd`. There is no
 * shared build step between TypeScript and GDScript in this project,
 * so this sync is currently manual; see that GDScript file's docstring
 * for the same note from the other side.
 *
 * TODO(Phase 14+): consider generating both files from one shared
 * spec if opcode drift becomes a recurring source of bugs.
 */
export enum MatchOpcode {
  /** Client -> Server: {position: {x,y,z}, deltaSeconds: number} */
  PlayerInput = 1,
  /** Server -> Client (all): full position snapshot of every player + zone state */
  Snapshot = 2,
  /** Server -> Client (single player): their position was corrected (anti-speed-hack) */
  PositionCorrection = 3,
  /** Client -> Server: {targetId, weaponClass, claimedDistanceMeters} — see ADR-0007 */
  WeaponFireClaim = 4,
  /** Server -> Client (all): {targetId, amount, remainingHealth, sourceId} — the kill feed's data source */
  DamageEvent = 5,
  /** Server -> Client (all): {userId} — a player was eliminated */
  EliminationEvent = 6,
}
