class_name AuthService
extends RefCounted
## Orchestrates the three login flows (Guest/Google/Email) into a
## single `AuthSession`. This is the "application" layer per
## ARCHITECTURE.md §3 — it coordinates the domain (AuthSession,
## NicknameRules) and infrastructure (GuestIdentityProvider,
## FirebaseWebIdentityProvider, NakamaClientAdapter) layers, but
## contains no engine-scene-tree code itself, so it's fully testable.
##
## Resolved from Services under the key "AuthService" (registered by
## this feature's composition root — see this feature's README for
## where that wiring happens once Phase 9's UI system gives it a
## screen to be constructed from).

var _nakama_client: NakamaClientAdapter
var _guest_provider: GuestIdentityProvider
var _firebase_provider: FirebaseWebIdentityProvider

var current_session: AuthSession = null

func _init(
	nakama_client: NakamaClientAdapter,
	guest_provider: GuestIdentityProvider,
	firebase_provider: FirebaseWebIdentityProvider
) -> void:
	_nakama_client = nakama_client
	_guest_provider = guest_provider
	_firebase_provider = firebase_provider

## Logs in as a guest using a locally persisted device ID. Works on
## every platform.
func login_as_guest_async() -> AuthSession:
	var device_id := _guest_provider.get_or_create_device_id()
	var result: AuthResult = await _nakama_client.authenticate_guest_async(device_id)
	return _finish_login(result)

## Logs in with a Google account. Only supported on HTML5/Web exports
## in the current implementation — see FirebaseWebIdentityProvider's
## scope note. Returns an invalid (empty) AuthSession with no
## exception thrown if called on an unsupported platform; callers
## should check `is_valid()` and surface a "not supported on this
## platform yet" message rather than assuming success.
func login_with_google_async() -> AuthSession:
	if not _firebase_provider.is_supported_on_this_platform():
		push_warning("AuthService: Google login is not yet supported on this platform.")
		return AuthSession.new()

	var id_token := await _firebase_provider.sign_in_with_google_async()
	if id_token.is_empty():
		push_warning("AuthService: Firebase Google sign-in failed: %s" % _firebase_provider.get_last_error())
		return AuthSession.new()

	var result: AuthResult = await _nakama_client.authenticate_google_async(id_token)
	return _finish_login(result)

## Logs in (or signs up, if create_if_missing) with email/password.
## Same platform limitation as login_with_google_async — email login
## also goes through Firebase in the current architecture (ADR-0004).
func login_with_email_async(email: String, password: String, create_if_missing: bool) -> AuthSession:
	if not _firebase_provider.is_supported_on_this_platform():
		push_warning("AuthService: Email login is not yet supported on this platform.")
		return AuthSession.new()

	var id_token := await _firebase_provider.sign_in_with_email_async(email, password, create_if_missing)
	if id_token.is_empty():
		push_warning("AuthService: Firebase email sign-in failed: %s" % _firebase_provider.get_last_error())
		return AuthSession.new()

	# Email login still authenticates to Nakama via authenticateCustom
	# with the Firebase-verified UID, exactly like Google — see
	# ADR-0004. Firebase itself is what distinguishes "Google" vs
	# "Email" sign-in; Nakama only ever sees a verified Firebase UID.
	var result: AuthResult = await _nakama_client.authenticate_google_async(id_token)
	return _finish_login(result)

## Attempts to claim `nickname` for the currently logged-in account.
## Runs the client-side format pre-check (NicknameRules) first purely
## for a fast local rejection — the server's response is still
## authoritative and is what this function ultimately returns.
## Returns a Dictionary: {"success": bool, ...} — see
## server/modules/authentication's claim_nickname RPC for the exact
## shape on success/failure.
func claim_nickname_async(nickname: String) -> Dictionary:
	var format_check := NicknameRules.validate_format(nickname)
	if not format_check["valid"]:
		return {"success": false, "errorCode": "INVALID_FORMAT", "message": format_check["reason"]}

	var response = await _nakama_client.claim_nickname_async(nickname)
	if response == null:
		return {"success": false, "errorCode": "TRANSPORT_ERROR", "message": "Could not reach the server."}

	if response.get("success", false) and current_session != null:
		current_session.nickname = nickname
		current_session.is_placeholder_nickname = false

	return response

func _finish_login(result: AuthResult) -> AuthSession:
	if not result.success:
		push_warning("AuthService: login failed: %s" % result.error_message)
		return AuthSession.new()

	var session := AuthSession.new(result.user_id, result.session_token, result.refresh_token)
	current_session = session
	return session
