extends GutTest
## Unit tests for client/features/ui/domain/loading_tips_provider.gd.

func test_current_returns_first_tip_initially() -> void:
	var provider := LoadingTipsProvider.new()
	assert_eq(provider.current(), LoadingTipsProvider.TIPS[0])

func test_next_advances_to_second_tip() -> void:
	var provider := LoadingTipsProvider.new()
	var result := provider.next()
	assert_eq(result, LoadingTipsProvider.TIPS[1])

func test_next_wraps_around_after_last_tip() -> void:
	var provider := LoadingTipsProvider.new()
	for i in provider.count():
		provider.next()
	assert_eq(provider.current(), LoadingTipsProvider.TIPS[0])

func test_count_matches_tips_array_size() -> void:
	var provider := LoadingTipsProvider.new()
	assert_eq(provider.count(), LoadingTipsProvider.TIPS.size())

func test_all_tips_are_non_empty_original_strings() -> void:
	for tip: String in LoadingTipsProvider.TIPS:
		assert_false(tip.is_empty())
