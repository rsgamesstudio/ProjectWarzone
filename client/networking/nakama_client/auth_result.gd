class_name AuthResult
extends RefCounted
## Outcome of an authentication attempt against Nakama, returned by
## NakamaClientAdapter. Callers depend on this small value object
## instead of the raw `NakamaSession`/`NakamaException` types from the
## vendored SDK, so the SDK stays swappable behind this adapter (see
## ARCHITECTURE.md §5 and this folder's README).

var success: bool
var session_token: String
var refresh_token: String
var user_id: String
var error_message: String

static func ok(p_session_token: String, p_refresh_token: String, p_user_id: String) -> AuthResult:
	var result := AuthResult.new()
	result.success = true
	result.session_token = p_session_token
	result.refresh_token = p_refresh_token
	result.user_id = p_user_id
	result.error_message = ""
	return result

static func failure(p_error_message: String) -> AuthResult:
	var result := AuthResult.new()
	result.success = false
	result.session_token = ""
	result.refresh_token = ""
	result.user_id = ""
	result.error_message = p_error_message
	return result
