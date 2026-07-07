class_name AuthSession
extends RefCounted
## Pure data representation of a logged-in player's session. Lives in
## the domain layer per ARCHITECTURE.md §3 — no Nakama SDK types, no
## engine coupling, fully testable in isolation.
##
## Distinct from the SDK's own `NakamaSession`: this is what the rest
## of the game (UI, other features) is allowed to depend on, so a
## future SDK swap only requires changes inside
## client/networking/nakama_client/, not throughout the codebase.

var user_id: String
var session_token: String
var refresh_token: String
var nickname: String
var is_placeholder_nickname: bool

func _init(
	p_user_id: String = "",
	p_session_token: String = "",
	p_refresh_token: String = "",
	p_nickname: String = "",
	p_is_placeholder_nickname: bool = true
) -> void:
	user_id = p_user_id
	session_token = p_session_token
	refresh_token = p_refresh_token
	nickname = p_nickname
	is_placeholder_nickname = p_is_placeholder_nickname

func is_valid() -> bool:
	return not user_id.is_empty() and not session_token.is_empty()
