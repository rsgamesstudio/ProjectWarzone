/**
 * Server-authoritative movement validation — the core of the
 * project's anti-speed-hack requirement. No Nakama dependency: pure
 * math, fully unit-testable.
 *
 * The client sends where it THINKS it is; this function decides what
 * the server actually accepts. It never trusts the client's claimed
 * position outright — it checks whether the implied speed since the
 * player's last accepted position is physically plausible, and if
 * not, clamps to the furthest point actually reachable in that time.
 */

export interface Vector3 {
  x: number;
  y: number;
  z: number;
}

export interface MovementValidationResult {
  accepted: boolean;
  resultingPosition: Vector3;
  wasCorrected: boolean;
}

function distance(a: Vector3, b: Vector3): number {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const dz = b.z - a.z;
  return Math.sqrt(dx * dx + dy * dy + dz * dz);
}

/**
 * @param previousPosition Last position the server accepted for this player.
 * @param requestedPosition Where the client claims it is now.
 * @param deltaSeconds Time elapsed since previousPosition was recorded.
 * @param maxSpeedMetersPerSecond The character's real maximum movement speed.
 * @param toleranceMultiplier Slack factor (e.g. 1.15) absorbing network
 *   jitter/legitimate variance — NOT an invitation for the client to
 *   move faster than the game allows, just enough to avoid punishing
 *   normal lag.
 */
export function validateMovement(
  previousPosition: Vector3,
  requestedPosition: Vector3,
  deltaSeconds: number,
  maxSpeedMetersPerSecond: number,
  toleranceMultiplier: number = 1.15
): MovementValidationResult {
  if (deltaSeconds <= 0) {
    // No time elapsed (or a nonsensical negative delta, e.g. an
    // out-of-order message) — the only safe accepted position is
    // where the player already was.
    return { accepted: false, resultingPosition: previousPosition, wasCorrected: true };
  }

  const traveled = distance(previousPosition, requestedPosition);
  const maxAllowed = maxSpeedMetersPerSecond * deltaSeconds * toleranceMultiplier;

  if (traveled <= maxAllowed) {
    return { accepted: true, resultingPosition: requestedPosition, wasCorrected: false };
  }

  // Clamp: move the player as far as they're legitimately allowed to,
  // in the direction they were trying to go, rather than either
  // accepting the impossible position or freezing them in place.
  const scale = maxAllowed / traveled;
  const corrected: Vector3 = {
    x: previousPosition.x + (requestedPosition.x - previousPosition.x) * scale,
    y: previousPosition.y + (requestedPosition.y - previousPosition.y) * scale,
    z: previousPosition.z + (requestedPosition.z - previousPosition.z) * scale,
  };

  return { accepted: false, resultingPosition: corrected, wasCorrected: true };
}
