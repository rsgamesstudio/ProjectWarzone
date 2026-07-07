/**
 * Thin wrapper around `nk.sqlQuery`/`nk.sqlExec` for the inventory/
 * economy tables (migration 0003). Same pattern as
 * `server/modules/authentication/src/infrastructure/warzone_db.ts` —
 * only this module's "infrastructure" layer is allowed to know actual
 * SQL/table shapes.
 *
 * NOTE: `findAccountIdByNakamaUserId` duplicates a small piece of
 * `authentication`'s `findOrCreateAccount` query. This module cannot
 * import authentication's TS source directly — each
 * `server/modules/<name>` is an independently bundled Nakama module
 * (see authentication's index.ts docstring on why) — so this is
 * accepted, deliberate duplication of one simple lookup, consistent
 * with this project's existing manual-sync tolerance for opcodes and
 * weapon definitions between modules/client and server.
 */

export function findAccountIdByNakamaUserId(nk: nkruntime.Nakama, nakamaUserId: string): string | null {
  const rows = nk.sqlQuery(`SELECT id FROM warzone_accounts WHERE nakama_user_id = $1;`, [nakamaUserId]);
  if (rows.length === 0) {
    return null;
  }
  return rows[0]["id"] as string;
}

export interface OwnedItem {
  itemId: string;
  acquiredAt: string;
}

export interface CurrencyBalance {
  credits: number;
  marks: number;
}

export function getOwnedItems(nk: nkruntime.Nakama, accountId: string): OwnedItem[] {
  const rows = nk.sqlQuery(
    `SELECT item_id, acquired_at FROM warzone_inventory_items WHERE account_id = $1;`,
    [accountId]
  );
  return rows.map((row) => ({
    itemId: row["item_id"] as string,
    acquiredAt: row["acquired_at"] as string,
  }));
}

export function ownsItem(nk: nkruntime.Nakama, accountId: string, itemId: string): boolean {
  const rows = nk.sqlQuery(
    `SELECT 1 FROM warzone_inventory_items WHERE account_id = $1 AND item_id = $2;`,
    [accountId, itemId]
  );
  return rows.length > 0;
}

/** Idempotent — granting an already-owned item is a safe no-op. */
export function grantItem(nk: nkruntime.Nakama, accountId: string, itemId: string): void {
  nk.sqlExec(
    `INSERT INTO warzone_inventory_items (account_id, item_id)
     VALUES ($1, $2)
     ON CONFLICT (account_id, item_id) DO NOTHING;`,
    [accountId, itemId]
  );
}

export function getEquippedSlots(nk: nkruntime.Nakama, accountId: string): { [slotKey: string]: string } {
  const rows = nk.sqlQuery(
    `SELECT slot_key, item_id FROM warzone_loadout_slots WHERE account_id = $1;`,
    [accountId]
  );
  const result: { [slotKey: string]: string } = {};
  for (const row of rows) {
    result[row["slot_key"] as string] = row["item_id"] as string;
  }
  return result;
}

export function equipItem(nk: nkruntime.Nakama, accountId: string, slotKey: string, itemId: string): void {
  nk.sqlExec(
    `INSERT INTO warzone_loadout_slots (account_id, slot_key, item_id, equipped_at)
     VALUES ($1, $2, $3, now())
     ON CONFLICT (account_id, slot_key)
     DO UPDATE SET item_id = EXCLUDED.item_id, equipped_at = now();`,
    [accountId, slotKey, itemId]
  );
}

export function getCurrencyBalance(nk: nkruntime.Nakama, accountId: string): CurrencyBalance {
  const rows = nk.sqlQuery(`SELECT credits, marks FROM warzone_accounts WHERE id = $1;`, [accountId]);
  if (rows.length === 0) {
    throw new Error(`getCurrencyBalance: no account found for id=${accountId}`);
  }
  return {
    credits: Number(rows[0]["credits"]),
    marks: Number(rows[0]["marks"]),
  };
}

/**
 * Atomically attempts to deduct `amountMarks` from the account's
 * balance in a single statement — `WHERE marks >= $2` combined with
 * `RETURNING id` means we get back exactly one row if and only if the
 * deduction actually happened, with no race window between a
 * separate "check balance" read and a later "deduct" write. Returns
 * false (having deducted nothing) if the balance was insufficient.
 */
export function tryDeductMarks(nk: nkruntime.Nakama, accountId: string, amountMarks: number): boolean {
  const rows = nk.sqlQuery(
    `UPDATE warzone_accounts SET marks = marks - $2 WHERE id = $1 AND marks >= $2 RETURNING id;`,
    [accountId, amountMarks]
  );
  return rows.length > 0;
}
