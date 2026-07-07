/**
 * Pure nickname validation rules — no dependency on the Nakama
 * runtime, Postgres, or anything else with I/O. This is the
 * "domain" layer per ARCHITECTURE.md §3: testable in complete
 * isolation, at full speed, with plain `node --test`.
 *
 * These rules mirror (but are not replaced by) lightweight
 * client-side checks in
 * client/features/authentication/domain/nickname_rules.gd, which
 * exist purely for immediate UX feedback. This module is the
 * authoritative source of truth — see ADR-0002.
 */

export const NICKNAME_MIN_LENGTH = 3;
export const NICKNAME_MAX_LENGTH = 20;

// Matches the CHECK constraint in
// server/db/postgres/migrations/0001_init_accounts_and_nicknames.up.sql
const NICKNAME_CHARSET_PATTERN = /^[A-Za-z0-9_]+$/;

// Deliberately small and reviewable. Extend via data (a moderation
// table) rather than growing this list unboundedly once live-content
// tooling exists (Phase 14+ admin tooling) — hardcoding is acceptable
// for a short, stable, safety-critical baseline list.
const RESERVED_NICKNAMES: ReadonlySet<string> = new Set([
  "admin",
  "administrator",
  "moderator",
  "rsgames",
  "projectwarzone",
  "system",
  "support",
  "gm",
  "root",
]);

export type NicknameValidationResult =
  | { valid: true }
  | { valid: false; reason: string };

/**
 * Validates a candidate nickname against length, charset, and
 * reserved-word rules. Does NOT check uniqueness — that requires a
 * database round trip and is handled separately by the claim
 * transaction in application/claim_nickname.ts, since uniqueness
 * can't be determined by a pure function.
 */
export function validateNicknameFormat(
  candidate: string
): NicknameValidationResult {
  if (candidate.length < NICKNAME_MIN_LENGTH) {
    return {
      valid: false,
      reason: `Nickname must be at least ${NICKNAME_MIN_LENGTH} characters.`,
    };
  }
  if (candidate.length > NICKNAME_MAX_LENGTH) {
    return {
      valid: false,
      reason: `Nickname must be at most ${NICKNAME_MAX_LENGTH} characters.`,
    };
  }
  if (!NICKNAME_CHARSET_PATTERN.test(candidate)) {
    return {
      valid: false,
      reason: "Nickname may only contain letters, numbers, and underscores.",
    };
  }
  if (RESERVED_NICKNAMES.has(candidate.toLowerCase())) {
    return {
      valid: false,
      reason: "This nickname is reserved and cannot be claimed.",
    };
  }
  return { valid: true };
}

/**
 * Generates a placeholder nickname for a brand-new guest account
 * (e.g. "Player483920"). Not guaranteed unique by construction — the
 * claim transaction still enforces uniqueness via the database's
 * case-insensitive unique index; on the astronomically unlikely
 * collision, the caller should regenerate and retry.
 */
export function generatePlaceholderNickname(): string {
  const suffix = Math.floor(100000 + Math.random() * 900000); // 6 digits
  return `Player${suffix}`;
}
