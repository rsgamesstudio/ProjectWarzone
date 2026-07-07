import { validateNicknameFormat } from "../domain/nickname_policy";
import {
  findOrCreateAccount,
  claimNickname as claimNicknameInDb,
  NicknameAlreadyTakenError,
} from "../infrastructure/warzone_db";

export type ClaimNicknameResult =
  | { success: true; nickname: string }
  | { success: false; errorCode: "INVALID_FORMAT" | "ALREADY_TAKEN"; message: string };

/**
 * Orchestrates a nickname claim: validate format (domain rule) then
 * attempt the atomic claim (infrastructure). Returns a structured
 * result rather than throwing, since "nickname already taken" and
 * "invalid format" are expected business outcomes the RPC handler
 * needs to relay back to the client as normal responses, not as
 * server errors.
 */
export function claimNicknameUseCase(
  nk: nkruntime.Nakama,
  nakamaUserId: string,
  requestedNickname: string
): ClaimNicknameResult {
  const formatResult = validateNicknameFormat(requestedNickname);
  if (!formatResult.valid) {
    return { success: false, errorCode: "INVALID_FORMAT", message: formatResult.reason };
  }

  const account = findOrCreateAccount(nk, nakamaUserId);

  try {
    claimNicknameInDb(nk, account.id, requestedNickname);
  } catch (err) {
    if (err instanceof NicknameAlreadyTakenError) {
      return { success: false, errorCode: "ALREADY_TAKEN", message: err.message };
    }
    throw err;
  }

  return { success: true, nickname: requestedNickname };
}
