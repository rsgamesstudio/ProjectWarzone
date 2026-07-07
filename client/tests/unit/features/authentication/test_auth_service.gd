extends GutTest
## Unit tests for client/features/authentication/application/auth_service.gd,
## using fakes for every infrastructure dependency so this exercises
## ONLY the orchestration logic — no network, no filesystem, no
## browser/JavaScriptBridge.

var nakama_fake: FakeNakamaClientAdapter
var guest_fake: FakeGuestIdentityProvider
var firebase_fake: FakeFirebaseWebIdentityProvider
var service: AuthService

func before_each() -> void:
	nakama_fake = FakeNakamaClientAdapter.new()
	guest_fake = FakeGuestIdentityProvider.new()
	firebase_fake = FakeFirebaseWebIdentityProvider.new()
	service = AuthService.new(nakama_fake, guest_fake, firebase_fake)

func test_guest_login_success_produces_valid_session() -> void:
	nakama_fake.guest_result = AuthResult.ok("token-1", "refresh-1", "user-1")

	var session: AuthSession = await service.login_as_guest_async()

	assert_true(session.is_valid())
	assert_eq(session.user_id, "user-1")
	assert_eq(session.session_token, "token-1")
	assert_eq(service.current_session, session)

func test_guest_login_failure_produces_invalid_session() -> void:
	nakama_fake.guest_result = AuthResult.failure("server unreachable")

	var session: AuthSession = await service.login_as_guest_async()

	assert_false(session.is_valid())
	assert_null(service.current_session)

func test_google_login_on_unsupported_platform_returns_invalid_session() -> void:
	firebase_fake.supported = false

	var session: AuthSession = await service.login_with_google_async()

	assert_false(session.is_valid())

func test_google_login_success_produces_valid_session() -> void:
	firebase_fake.supported = true
	firebase_fake.google_id_token_to_return = "firebase-id-token"
	nakama_fake.google_result = AuthResult.ok("token-2", "refresh-2", "user-2")

	var session: AuthSession = await service.login_with_google_async()

	assert_true(session.is_valid())
	assert_eq(session.user_id, "user-2")

func test_google_login_firebase_failure_never_calls_nakama() -> void:
	firebase_fake.supported = true
	firebase_fake.google_id_token_to_return = "" # empty token = Firebase sign-in failed
	nakama_fake.google_result = AuthResult.ok("should-not-be-used", "x", "x")

	var session: AuthSession = await service.login_with_google_async()

	assert_false(session.is_valid(), "an empty Firebase token should short-circuit before reaching Nakama")

func test_claim_nickname_rejects_invalid_format_without_calling_server() -> void:
	nakama_fake.claim_response = {"success": true, "nickname": "should-not-be-returned"}

	var result: Dictionary = await service.claim_nickname_async("no spaces")

	assert_false(result["success"])
	assert_eq(result["errorCode"], "INVALID_FORMAT")

func test_claim_nickname_forwards_valid_format_to_server_and_updates_session() -> void:
	nakama_fake.guest_result = AuthResult.ok("token", "refresh", "user-1")
	await service.login_as_guest_async()
	nakama_fake.claim_response = {"success": true, "nickname": "Sukesh_D"}

	var result: Dictionary = await service.claim_nickname_async("Sukesh_D")

	assert_true(result["success"])
	assert_eq(service.current_session.nickname, "Sukesh_D")
	assert_false(service.current_session.is_placeholder_nickname)

func test_claim_nickname_transport_failure_is_reported() -> void:
	nakama_fake.claim_response = null

	var result: Dictionary = await service.claim_nickname_async("ValidName")

	assert_false(result["success"])
	assert_eq(result["errorCode"], "TRANSPORT_ERROR")
