import { findOrCreateAccount, ensurePlaceholderNickname } from "../infrastructure/warzone_db";
import { generatePlaceholderNickname } from "../domain/nickname_policy";

/**
 * Use case run from every `after_authenticate_*` hook (device, email,
 * custom). Idempotent — safe to run on every login, not just the
 * first one, since both underlying infrastructure calls are
 * themselves idempotent (ON CONFLICT DO NOTHING).
 */
export function provisionAccountIfNeeded(nk: nkruntime.Nakama, nakamaUserId: string): void {
  const account = findOrCreateAccount(nk, nakamaUserId);
  const placeholder = generatePlaceholderNickname();
  ensurePlaceholderNickname(nk, account.id, placeholder);
}
