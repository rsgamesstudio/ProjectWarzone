import { test } from "node:test";
import assert from "node:assert/strict";
import {
  validateNicknameFormat,
  generatePlaceholderNickname,
  NICKNAME_MIN_LENGTH,
  NICKNAME_MAX_LENGTH,
} from "./nickname_policy";

test("accepts a normal valid nickname", () => {
  const result = validateNicknameFormat("Sukesh_D");
  assert.equal(result.valid, true);
});

test("rejects nickname shorter than minimum length", () => {
  const result = validateNicknameFormat("ab");
  assert.equal(result.valid, false);
  if (!result.valid) {
    assert.match(result.reason, /at least/);
  }
});

test("rejects nickname longer than maximum length", () => {
  const tooLong = "a".repeat(NICKNAME_MAX_LENGTH + 1);
  const result = validateNicknameFormat(tooLong);
  assert.equal(result.valid, false);
  if (!result.valid) {
    assert.match(result.reason, /at most/);
  }
});

test("accepts nickname at exactly the minimum length", () => {
  const exact = "a".repeat(NICKNAME_MIN_LENGTH);
  const result = validateNicknameFormat(exact);
  assert.equal(result.valid, true);
});

test("accepts nickname at exactly the maximum length", () => {
  const exact = "a".repeat(NICKNAME_MAX_LENGTH);
  const result = validateNicknameFormat(exact);
  assert.equal(result.valid, true);
});

test("rejects nickname with disallowed characters", () => {
  const cases = ["bad name", "bad-name", "bad!name", "bad.name", "emoji😀"];
  for (const candidate of cases) {
    const result = validateNicknameFormat(candidate);
    assert.equal(result.valid, false, `expected "${candidate}" to be rejected`);
  }
});

test("rejects reserved nicknames case-insensitively", () => {
  for (const candidate of ["admin", "Admin", "ADMIN", "RSGames"]) {
    const result = validateNicknameFormat(candidate);
    assert.equal(result.valid, false, `expected "${candidate}" to be rejected as reserved`);
  }
});

test("generatePlaceholderNickname produces a well-formed placeholder", () => {
  const nickname = generatePlaceholderNickname();
  assert.match(nickname, /^Player\d{6}$/);
  // A generated placeholder must itself pass format validation, or
  // account provisioning would break on its own output.
  const result = validateNicknameFormat(nickname);
  assert.equal(result.valid, true);
});

test("generatePlaceholderNickname is not constant across calls", () => {
  const samples = new Set(Array.from({ length: 20 }, () => generatePlaceholderNickname()));
  assert.ok(samples.size > 1, "expected some variation across 20 generated placeholders");
});
