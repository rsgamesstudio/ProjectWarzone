import { test } from "node:test";
import assert from "node:assert/strict";
import { claimNicknameUseCase } from "./claim_nickname";

/**
 * A minimal in-memory fake of the two SQL methods our infrastructure
 * layer calls, standing in for `nk`. This is a smoke test of the
 * application layer's orchestration logic (format validation -> find
 * account -> claim), not a substitute for a real integration test
 * against actual Postgres (that requires the Docker stack — see
 * client/tests/integration equivalent pattern, and the manual
 * testing checklist in the phase report).
 */
function makeFakeNakama(): nkruntime.Nakama {
  const accounts = new Map<string, string>(); // nakama_user_id -> account_id
  const nicknames = new Map<string, string>(); // account_id -> nickname (lowercased for uniqueness)
  let nextAccountId = 1;

  const fake = {
    sqlQuery(query: string, args: unknown[] = []): { [column: string]: unknown }[] {
      if (query.includes("INSERT INTO warzone_accounts")) {
        const nakamaUserId = args[0] as string;
        if (!accounts.has(nakamaUserId)) {
          accounts.set(nakamaUserId, `account-${nextAccountId++}`);
        }
        const id = accounts.get(nakamaUserId)!;
        return [{ id, nakama_user_id: nakamaUserId }];
      }
      throw new Error(`Unhandled fake sqlQuery: ${query}`);
    },
    sqlExec(query: string, args: unknown[] = []): { rowsAffected: number } {
      if (query.includes("UPDATE warzone_nicknames")) {
        const [accountId, newNickname] = args as [string, string];
        const lower = newNickname.toLowerCase();
        for (const [existingAccountId, existingNickname] of nicknames.entries()) {
          if (existingNickname === lower && existingAccountId !== accountId) {
            throw new Error('duplicate key value violates unique constraint "idx_warzone_nicknames_lower_unique"');
          }
        }
        nicknames.set(accountId, lower);
        return { rowsAffected: 1 };
      }
      throw new Error(`Unhandled fake sqlExec: ${query}`);
    },
  };

  return fake as unknown as nkruntime.Nakama;
}

test("claimNicknameUseCase succeeds for a valid, unclaimed nickname", () => {
  const nk = makeFakeNakama();
  const result = claimNicknameUseCase(nk, "firebase-uid-1", "Sukesh_D");
  assert.deepEqual(result, { success: true, nickname: "Sukesh_D" });
});

test("claimNicknameUseCase rejects invalid format before touching the database", () => {
  const nk = makeFakeNakama();
  const result = claimNicknameUseCase(nk, "firebase-uid-1", "no spaces allowed");
  assert.equal(result.success, false);
  if (!result.success) {
    assert.equal(result.errorCode, "INVALID_FORMAT");
  }
});

test("claimNicknameUseCase rejects a nickname already claimed by another account", () => {
  const nk = makeFakeNakama();
  claimNicknameUseCase(nk, "firebase-uid-1", "TakenName");

  const result = claimNicknameUseCase(nk, "firebase-uid-2", "takenname"); // case-insensitive clash

  assert.equal(result.success, false);
  if (!result.success) {
    assert.equal(result.errorCode, "ALREADY_TAKEN");
  }
});

test("claimNicknameUseCase allows the same account to change its own nickname", () => {
  const nk = makeFakeNakama();
  claimNicknameUseCase(nk, "firebase-uid-1", "FirstName");
  const result = claimNicknameUseCase(nk, "firebase-uid-1", "SecondName");
  assert.deepEqual(result, { success: true, nickname: "SecondName" });
});
