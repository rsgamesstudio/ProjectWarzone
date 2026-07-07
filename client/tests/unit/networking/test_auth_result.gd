extends GutTest
## Unit tests for client/networking/nakama_client/auth_result.gd.

func test_ok_result_has_success_true_and_no_error() -> void:
	var result := AuthResult.ok("token", "refresh", "user-1")
	assert_true(result.success)
	assert_eq(result.session_token, "token")
	assert_eq(result.refresh_token, "refresh")
	assert_eq(result.user_id, "user-1")
	assert_eq(result.error_message, "")

func test_failure_result_has_success_false_and_message() -> void:
	var result := AuthResult.failure("invalid credentials")
	assert_false(result.success)
	assert_eq(result.error_message, "invalid credentials")
	assert_eq(result.session_token, "")
