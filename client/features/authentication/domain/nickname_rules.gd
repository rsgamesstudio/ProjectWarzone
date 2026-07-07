class_name NicknameRules
extends RefCounted
## Client-side mirror of the format rules enforced authoritatively by
## server/modules/authentication/src/domain/nickname_policy.ts (see
## ADR-0002). Exists ONLY for immediate UX feedback (e.g. disabling a
## "Claim" button, showing an inline error) before the player even
## submits a request — it is NOT the source of truth. The server
## re-validates everything independently and its decision always wins;
## a claim can still be rejected by the server (most commonly for
## uniqueness, which this client-side check cannot know about at all).
##
## Keep these constants in sync with the server's nickname_policy.ts
## by hand for now — Phase 14+ tooling may generate both from one
## shared spec if drift becomes a recurring problem.

const MIN_LENGTH: int = 3
const MAX_LENGTH: int = 20
const CHARSET_REGEX_PATTERN: String = "^[A-Za-z0-9_]+$"

static func validate_format(candidate: String) -> Dictionary:
	if candidate.length() < MIN_LENGTH:
		return {"valid": false, "reason": "Nickname must be at least %d characters." % MIN_LENGTH}
	if candidate.length() > MAX_LENGTH:
		return {"valid": false, "reason": "Nickname must be at most %d characters." % MAX_LENGTH}

	var regex := RegEx.new()
	regex.compile(CHARSET_REGEX_PATTERN)
	if not regex.search(candidate):
		return {"valid": false, "reason": "Nickname may only contain letters, numbers, and underscores."}

	return {"valid": true, "reason": ""}
