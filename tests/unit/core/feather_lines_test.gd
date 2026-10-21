extends GutTest
## Dusk explains every feather change of the day, in order, with its cause (WP5, D15, D36):
## citations, Huginn's extra answer, Hel's reward, the quota, a demotion, and the loss cap.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")


func test_a_day_with_a_citation_and_a_met_quota_lists_both_in_order() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 3)
	var dawn: int = desk.dusk_report().feathers
	desk.stamp(Realm.VALHALLA)
	desk.next_soul()
	var report: DuskReport = desk.dusk_report()
	assert_eq(report.feathers_at_dawn, dawn)
	assert_eq(report.feather_lines, ["Citation (Grim): -2.", "Quota: +2."] as Array[String])
	assert_eq(report.feathers, dawn)


func test_hels_reward_and_a_bought_answer_are_listed() -> void:
	var days: Array[DayRules] = Fixture.days()
	days[2].huginn_answers = 1
	var desk := DeskCommands.new()
	desk.start_run(days, Fixture.queues(), Fixture.rules(), Fixture.variants())
	desk.debug_jump(3, 3)
	desk.stamp(Realm.HEL)
	desk.next_soul()
	desk.pin("C2", "W1")
	desk.ask_huginn(0)
	desk.buy_huginn_answer()
	desk.stamp(Realm.HEL)
	assert_eq(
		desk.dusk_report().feather_lines,
		(
			[
				"Citation (Ragna): -2.",
				"Hel paid 4.",
				"Huginn's extra answer: -2.",
				"Quota: -1.",
			]
			as Array[String]
		)
	)


func test_a_demotion_and_the_loss_cap_are_explained() -> void:
	var rules: SliceRules = Fixture.rules()
	rules.start_feathers = 3
	rules.quota_met_reward = 0
	var desk: DeskCommands = Fixture.desk(rules)
	desk.debug_jump(2, 1)
	desk.stamp(Realm.HEL)
	desk.next_soul()
	desk.stamp(Realm.VALHALLA)
	desk.next_soul()
	desk.stamp(Realm.VALHALLA)
	desk.next_soul()
	assert_eq(
		desk.dusk_report().feather_lines,
		(
			[
				"Citation (Sigvaldi): -2.",
				"Citation (Hakon): -2.",
				"Demoted to Gate-warden: feathers refilled to 5.",
				"Citation (Grim): -1.",
				"Loss cap reached: -1 instead of -2.",
				"Quota: +0.",
			]
			as Array[String]
		)
	)


func test_restart_clears_the_days_feather_lines() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 3)
	desk.stamp(Realm.VALHALLA)
	desk.restart_run()
	desk.debug_jump(1, 3)
	desk.stamp(Realm.HEL)
	assert_eq(desk.dusk_report().feather_lines, ["Quota: +2."] as Array[String])
	assert_eq(desk.dusk_report().feathers_at_dawn, 10)
