extends GutTest
## Feathers (GDD §3.8, D36, D40): losses capped at 5 a day, spends uncapped, demotion after every
## change, and the reward after the citation.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")


func test_the_clerk_starts_with_ten_feathers_at_the_top_rank() -> void:
	var economy := Economy.new(SliceRules.new())
	assert_eq(economy.feathers, 10)
	assert_eq(economy.rank, 0)
	assert_eq(economy.rank_name(), "Chooser of the Slain")


func test_losses_are_capped_at_five_a_day() -> void:
	var economy := Economy.new(SliceRules.new())
	var lost: Array[int] = [economy.lose(2), economy.lose(2), economy.lose(2), economy.lose(2)]
	assert_eq(lost, [2, 2, 1, 0] as Array[int])
	assert_eq(economy.feathers, 5)
	economy.start_day()
	assert_eq(economy.lose(2), 2, "a new day resets the cap")
	assert_eq(economy.feathers, 3)


func test_spends_are_never_capped_and_never_count_as_losses() -> void:
	var economy := Economy.new(SliceRules.new())
	economy.lose(5)
	economy.spend(2)
	assert_eq(economy.feathers, 3, "a spend applies past the loss cap")
	assert_eq(economy.losses_today, 5)


func test_zero_feathers_demotes_and_refills_after_any_change() -> void:
	var economy := Economy.new(SliceRules.new())
	economy.feathers = 2
	economy.spend(2)
	assert_eq([economy.rank, economy.feathers, economy.demotions], [1, 5, 1], "after a spend")
	economy.start_day()
	economy.lose(5)
	assert_eq([economy.rank, economy.feathers, economy.demotions], [2, 5, 2], "after a loss")


func test_the_lowest_rank_stays_at_zero() -> void:
	var economy := Economy.new(SliceRules.new())
	economy.rank = economy.lowest_rank()
	economy.feathers = 2
	economy.lose(3)
	assert_eq(economy.feathers, 0, "Cast down is outside the slice")
	assert_eq(economy.rank, 2)


func test_hel_pays_after_the_citation_so_the_citation_can_demote_first() -> void:
	# Feathers 2 at Ragna: the citation (-2) demotes and refills to 5, then Hel pays 4.
	# Paid first, the same stamp would have ended at 4 with no demotion.
	var rules: SliceRules = Fixture.rules()
	rules.start_feathers = 2
	rules.quota_met_reward = 0
	var desk: DeskCommands = Fixture.desk(rules)
	desk.debug_jump(3, 3)
	assert_eq(desk.current_encounter().soul_name, "Ragna")
	assert_eq(desk.feathers(), 2)
	var result: StampResult = desk.stamp(Realm.HEL)
	assert_true(result.citation)
	assert_eq(result.reward, 4)
	assert_true(result.demoted)
	assert_eq(desk.feathers(), 9)
	assert_eq(result.feathers_delta, 7)
	assert_eq(desk.rank(), 1)
