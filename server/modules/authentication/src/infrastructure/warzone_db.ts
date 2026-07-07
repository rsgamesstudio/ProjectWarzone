
/**
 * Thin wrapper around `nk.sqlQuery`/`nk.sqlExec` for the `warzone_*`
 * tables (see docs/adr/ADR-0002, ADR-0003). This is the
 * "infrastructure" layer per ARCHITECTURE.md §3 — the only place in
 * this module allowed to know actual SQL/table shapes. Application
 * use cases call these functions rather than embedding SQL
 * themselves.
 *
 * Every statement here is written to be atomic as a single SQL
 * statement, since the Nakama JS runtime does not expose explicit
 * multi-statement transaction control (BEGIN/COMMIT) across separate
 * sqlExec/sqlQuery calls.
 */

export interface WarzoneAccount {
  id: string;
  nakamaUserId: string;
}

export interface WarzoneNickname {
  id: string;
  accountId: string;
  nickname: string;
  isPlaceholder: boolean;
  changeCount: number;
}

/**
 * Idempotently ensures a `warzone_accounts` row exists for the given
 * Nakama user ID, returning the (possibly pre-existing) account.
 * Safe to call on every login, not just first login.
 */
export function findOrCreateAccount(
  nk: nkruntime.Nakama,
  nakamaUserId: string
): WarzoneAccount {
  const query = `
    WITH inserted AS (
      INSERT INTO warzone_accounts (nakama_user_id)
      VALUES ($1)
      ON CONFLICT (nakama_user_id) DO NOTHING
      RETURNING id, nakama_user_id
    )
    SELECT id, nakama_user_id FROM inserted
    UNION ALL
    SELECT id, nakama_user_id FROM warzone_accounts WHERE nakama_user_id = $1
    LIMIT 1;
  `;
  const result = nk.sqlQuery(query, [nakamaUserId]);
  if (result.length === 0) {
    throw new Error(
      `findOrCreateAccount: no row returned for nakama_user_id=${nakamaUserId}, this should be impossible`
    );
  }
  const row = result[0] as Record<string, string>;
  return { id: row["id"], nakamaUserId: row["nakama_user_id"] };
}

/**
 * Idempotently ensures a placeholder nickname row exists for the
 * given account. If a nickname already exists (placeholder or
 * claimed), this is a no-op — relies on the UNIQUE(account_id)
 * constraint from migration 0002 for race safety.
 */
export function ensurePlaceholderNickname(
  nk: nkruntime.Nakama,
  accountId: string,
  placeholder: string
): void {
  const query = `
    INSERT INTO warzone_nicknames (account_id, nickname, is_placeholder)
    VALUES ($1, $2, true)
    ON CONFLICT (account_id) DO NOTHING;
  `;
  nk.sqlExec(query, [accountId, placeholder]);
}

export function findNicknameByAccountId(
  nk: nkruntime.Nakama,
  accountId: string
): WarzoneNickname | null {
  const result = nk.sqlQuery(
    `SELECT id, account_id, nickname, is_placeholder, change_count
     FROM warzone_nicknames WHERE account_id = $1;`,
    [accountId]
  );
  if (result.length === 0) {
    return null;
  }
  const row = result[0] as Record<string, unknown>;
  return {
    id: row["id"] as string,
    accountId: row["account_id"] as string,
    nickname: row["nickname"] as string,
    isPlaceholder: row["is_placeholder"] as boolean,
    changeCount: Number(row["change_count"]),
  };
}

export class NicknameAlreadyTakenError extends Error {
  constructor(nickname: string) {
    super(`Nickname "${nickname}" is already taken.`);
    this.name = "NicknameAlreadyTakenError";
  }
}

/**
 * Atomically claims `newNickname` for `accountId`, replacing whatever
 * nickname (placeholder or previously claimed) that account had. The
 * uniqueness check is enforced by the database's case-insensitive
 * unique index (migration 0001) — if the UPDATE would violate it,
 * Postgres raises a unique_violation, which we translate into
 * `NicknameAlreadyTakenError` for the application layer to handle as
 * an expected business outcome rather than a system error.
 */
export function claimNickname(
  nk: nkruntime.Nakama,
  accountId: string,
  newNickname: string
): void {
  const query = `
    UPDATE warzone_nicknames
    SET nickname = $2,
        is_placeholder = false,
        last_changed_at = now(),
        change_count = change_count + 1
    WHERE account_id = $1;
  `;
  try {
    nk.sqlExec(query, [accountId, newNickname]);
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    if (message.toLowerCase().includes("unique") || message.toLowerCase().includes("duplicate")) {
      throw new NicknameAlreadyTakenError(newNickname);
    }
    throw err;
  }
}
