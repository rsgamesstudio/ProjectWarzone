/**
 * Minimal in-memory fake of `nk.sqlQuery`/`nk.sqlExec` covering
 * exactly the queries this module's infrastructure layer issues.
 * Not a general-purpose SQL engine — just enough behavior to test
 * the application layer's orchestration without a real Postgres
 * connection. Real integration testing against actual Postgres is
 * covered by the manual testing checklist in the phase report.
 */

interface FakeAccount {
  id: string;
  credits: number;
  marks: number;
}

export class FakeNakama {
  accounts: Map<string, FakeAccount> = new Map(); // keyed by account id
  inventoryItems: Map<string, Set<string>> = new Map(); // accountId -> set of itemIds
  loadoutSlots: Map<string, Map<string, string>> = new Map(); // accountId -> (slotKey -> itemId)
  nakamaUserIdToAccountId: Map<string, string> = new Map();

  addAccount(accountId: string, nakamaUserId: string, credits = 0, marks = 0): void {
    this.accounts.set(accountId, { id: accountId, credits, marks });
    this.nakamaUserIdToAccountId.set(nakamaUserId, accountId);
    this.inventoryItems.set(accountId, new Set());
    this.loadoutSlots.set(accountId, new Map());
  }

  asNk(): nkruntime.Nakama {
    const self = this;
    return {
      sqlQuery(query: string, args: unknown[] = []): { [column: string]: unknown }[] {
        if (query.includes("SELECT id FROM warzone_accounts WHERE nakama_user_id")) {
          const accountId = self.nakamaUserIdToAccountId.get(args[0] as string);
          return accountId ? [{ id: accountId }] : [];
        }
        if (query.includes("SELECT item_id, acquired_at FROM warzone_inventory_items")) {
          const items = self.inventoryItems.get(args[0] as string) ?? new Set();
          return Array.from(items).map((itemId) => ({ item_id: itemId, acquired_at: "2026-01-01T00:00:00Z" }));
        }
        if (query.includes("SELECT 1 FROM warzone_inventory_items")) {
          const items = self.inventoryItems.get(args[0] as string) ?? new Set();
          return items.has(args[1] as string) ? [{ "1": 1 }] : [];
        }
        if (query.includes("SELECT slot_key, item_id FROM warzone_loadout_slots")) {
          const slots = self.loadoutSlots.get(args[0] as string) ?? new Map();
          return Array.from(slots.entries()).map(([slot_key, item_id]) => ({ slot_key, item_id }));
        }
        if (query.includes("SELECT credits, marks FROM warzone_accounts")) {
          const account = self.accounts.get(args[0] as string);
          if (!account) return [];
          return [{ credits: account.credits, marks: account.marks }];
        }
        if (query.includes("UPDATE warzone_accounts SET marks = marks -")) {
          const accountId = args[0] as string;
          const amount = args[1] as number;
          const account = self.accounts.get(accountId);
          if (!account || account.marks < amount) {
            return [];
          }
          account.marks -= amount;
          return [{ id: accountId }];
        }
        throw new Error(`FakeNakama: unhandled sqlQuery: ${query}`);
      },
      sqlExec(query: string, args: unknown[] = []): { rowsAffected: number } {
        if (query.includes("INSERT INTO warzone_inventory_items")) {
          const accountId = args[0] as string;
          const itemId = args[1] as string;
          if (!self.inventoryItems.has(accountId)) {
            self.inventoryItems.set(accountId, new Set());
          }
          self.inventoryItems.get(accountId)!.add(itemId);
          return { rowsAffected: 1 };
        }
        if (query.includes("INSERT INTO warzone_loadout_slots")) {
          const [accountId, slotKey, itemId] = args as [string, string, string];
          if (!self.loadoutSlots.has(accountId)) {
            self.loadoutSlots.set(accountId, new Map());
          }
          self.loadoutSlots.get(accountId)!.set(slotKey, itemId);
          return { rowsAffected: 1 };
        }
        throw new Error(`FakeNakama: unhandled sqlExec: ${query}`);
      },
    } as unknown as nkruntime.Nakama;
  }
}
