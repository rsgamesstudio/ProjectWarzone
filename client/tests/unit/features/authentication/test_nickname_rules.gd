extends GutTest
## Unit tests for client/features/authentication/domain/nickname_rules.gd.

func test_accepts_a_normal_valid_nickname() -> void:
	var result := NicknameRules.validate_format("Sukesh_D")
	assert_true(result["valid"])

func test_rejects_nickname_shorter_than_minimum() -> void:
	var result := NicknameRules.validate_format("ab")
	assert_false(result["valid"])
	assert_string_contains(result["reason"], "at least")

func test_rejects_nickname_longer_than_maximum() -> void:
	var too_long := "a".repeat(NicknameRules.MAX_LENGTH + 1)
	var result := NicknameRules.validate_format(too_long)
	assert_false(result["valid"])
	assert_string_contains(result["reason"], "at most")

func test_accepts_nickname_at_exactly_minimum_length() -> void:
	var exact := "a".repeat(NicknameRules.MIN_LENGTH)
	var result := NicknameRules.validate_format(exact)
	assert_true(result["valid"])

func test_accepts_nickname_at_exactly_maximum_length() -> void:
	var exact := "a".repeat(NicknameRules.MAX_LENGTH)
	var result := NicknameRules.validate_format(exact)
	assert_true(result["valid"])

func test_rejects_nickname_with_spaces() -> void:
	var result := NicknameRules.validate_format("bad name")
	assert_false(result["valid"])

func test_rejects_nickname_with_special_characters() -> void:
	for candidate in ["bad-name", "bad!name", "bad.name"]:
		var result := NicknameRules.validate_format(candidate)
		assert_false(result["valid"], "expected '%s' to be rejected" % candidate)

func test_accepts_underscores_and_digits() -> void:
	var result := NicknameRules.validate_format("Player_123")
	assert_true(result["valid"])
