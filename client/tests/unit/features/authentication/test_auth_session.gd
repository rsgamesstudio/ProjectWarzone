extends GutTest
## Unit tests for client/features/authentication/domain/auth_session.gd.

func test_default_session_is_invalid() -> void:
	var session := AuthSession.new()
	assert_false(session.is_valid())

func test_session_with_user_id_and_token_is_valid() -> void:
	var session := AuthSession.new("user-123", "token-abc")
	assert_true(session.is_valid())

func test_session_missing_token_is_invalid() -> void:
	var session := AuthSession.new("user-123", "")
	assert_false(session.is_valid())

func test_session_missing_user_id_is_invalid() -> void:
	var session := AuthSession.new("", "token-abc")
	assert_false(session.is_valid())

func test_new_session_defaults_to_placeholder_nickname() -> void:
	var session := AuthSession.new("user-123", "token-abc")
	assert_true(session.is_placeholder_nickname)
