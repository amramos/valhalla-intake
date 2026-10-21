extends GutTest
## The slice's flow and shell with the full content (D15, D23, D31, D34): the title, dawn cards,
## the dusk sequence with "Next" and "Skip all", the ledger tray, the pause with its confirmed
## restart and quit, and the ending with "Play again". Days are played through DeskCommands
## (each soul stamped to its legal door) and every screen is driven through its own buttons.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const TITLE_SCENE := preload("res://scenes/title/title.tscn")

var _viewport: SubViewport = null
var _desk: Desk = null
var _system: DeskSystem = null


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.quit_closes_game = false
	_viewport.add_child(_desk)
	_system = _desk.system()


func test_the_title_offers_start_and_quit_in_the_slices_words() -> void:
	var title: TitleScreen = TITLE_SCENE.instantiate() as TitleScreen
	title.change_scene = false
	add_child_autofree(title)
	var text: DeskText = SliceLoader.load_slice().slice_rules().text
	assert_eq(title.start_button().text, text.start_label)
	assert_eq(title.quit_button().text, text.quit_label)
	watch_signals(title)
	title.start_button().pressed.emit()
	assert_signal_emitted(title, "start_requested")
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/title/title.tscn"
	)


func test_each_dawn_card_shows_its_days_lines_with_the_clock_filled() -> void:
	assert_eq(_card(), _joined(ScreenText.dawn_lines(_commands().day_rules())))
	assert_eq(_system.phase_card.next_button().text, _text().begin_label)
	_play_to_dusk(1)
	_skip_dusk()
	assert_eq(_commands().day_number(), 2)
	assert_string_contains(_card(), "The clock: 5:00.", "{clock} as m:ss (A5)")
	assert_false(_card().contains("{clock}"))


func test_the_dusk_shows_its_cards_one_by_one_then_the_next_day() -> void:
	_play_to_dusk(1)
	var cards: Array[String] = ScreenText.dusk_cards(_commands().dusk_report(), _rules())
	assert_gt(cards.size(), 1)
	for index: int in range(cards.size()):
		assert_string_contains(_card(), cards[index], "card %d" % (index + 1))
		assert_string_contains(_card(), _text().dusk_title_format % 1)
		var last: bool = index == cards.size() - 1
		assert_eq(_system.phase_card.skip_button().visible, not last, "Skip all until the last")
		_press(_system.phase_card.next_button())
	assert_eq(_commands().phase(), RunState.DAWN)
	assert_eq(_commands().day_number(), 2)


func test_the_dusk_names_the_rank_and_explains_the_feathers() -> void:
	_play_to_dusk(1)
	var all: String = _joined(ScreenText.dusk_cards(_commands().dusk_report(), _rules()))
	assert_string_contains(all, _text().rank_format % _commands().rank_name(), "D21")
	var report: DuskReport = _commands().dusk_report()
	assert_string_contains(
		all, _text().feathers_dawn_format % [report.feathers_at_dawn, report.feathers]
	)


func test_skip_all_keeps_hels_offer_in_the_ledger() -> void:
	_play_to_dusk(2)
	assert_ne(_commands().ledger_line(), "", "Hel made her offer at day 2's dusk")
	_press(_system.phase_card.skip_button())
	assert_eq(_commands().day_number(), 3, "Skip all goes straight to the next dawn")
	assert_eq(_commands().promise_state(), RunState.PROMISE_OPEN, "the request is recorded (D15)")
	_system.ledger_tray.press()
	assert_eq(_system.ledger_tray.shown_line(), _commands().ledger_line(), "the tray shows it (D3)")


func test_the_ledger_tray_shows_the_empty_ledger_before_any_request() -> void:
	_system.ledger_tray.press()
	assert_true(_system.ledger_tray.is_open())
	assert_eq(_system.ledger_tray.shown_line(), _text().ledger_empty)
	_system.ledger_tray.press()
	assert_false(_system.ledger_tray.is_open())


func test_a_double_click_on_a_card_never_skips_a_card() -> void:
	_play_to_dusk(1)
	var next: GuardedButton = _system.phase_card.next_button()
	next.arm_now()
	var shown: String = _card()
	_click(next.get_global_rect().get_center(), false)
	var second: String = _card()
	assert_ne(second, shown, "one click moves one card")
	_click(next.get_global_rect().get_center(), true)
	assert_eq(_card(), second, "the double-click's second press is swallowed")
	_click(next.get_global_rect().get_center(), false)
	assert_eq(_card(), second, "and the new card is not armed yet")


func test_esc_pauses_and_dims_the_desk_and_resume_carries_on() -> void:
	_press(_system.phase_card.next_button())
	_escape()
	assert_true(_desk.pause_overlay().is_open())
	assert_true(_commands().is_paused())
	_desk._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_desk._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_true(_commands().is_paused(), "regaining focus does not lift the pause")
	_press(_desk.pause_overlay().resume_button())
	assert_false(_desk.pause_overlay().is_open())
	assert_false(_commands().is_paused())


func test_restart_is_confirmed_and_restores_the_whole_day_one_dawn() -> void:
	_play_to_dusk(2)
	_press(_system.phase_card.skip_button())
	_press(_system.phase_card.next_button())
	_commands().pin("C1", "W1")
	assert_ne(_commands().ledger_line(), "")
	_escape()
	_press(_desk.pause_overlay().restart_button())
	assert_eq(_desk.pause_overlay().question(), _text().restart_confirm, "restart asks first")
	_press(_desk.pause_overlay().no_button())
	assert_eq(_commands().day_number(), 3, "No changes nothing")
	_press(_desk.pause_overlay().restart_button())
	_press(_desk.pause_overlay().yes_button())
	assert_false(_desk.pause_overlay().is_open())
	assert_eq(_commands().phase(), RunState.DAWN)
	assert_eq(_commands().day_number(), 1)
	assert_eq(_commands().feathers(), _rules().start_feathers)
	assert_eq(_commands().ledger_line(), "", "the ledger is empty again")
	assert_eq(_commands().hel_tide(), 0)
	assert_eq(_card(), _joined(ScreenText.dawn_lines(_commands().day_rules())), "day 1's dawn")
	assert_eq(_system.caption_strip.shown_text(), "")
	_press(_system.phase_card.next_button())
	assert_eq(_system.soul.soul_name(), "Ulf")
	assert_eq(_commands().threads().size(), 0)
	assert_eq(_system.hud.shown_time(), "untimed")
	assert_ne(_system.mentor_bubble.shown_text(), "", "the mentor guides Ulf again")


func test_quit_is_confirmed_before_it_closes_the_game() -> void:
	watch_signals(_desk)
	_escape()
	_press(_desk.pause_overlay().quit_button())
	assert_eq(_desk.pause_overlay().question(), _text().quit_confirm)
	_press(_desk.pause_overlay().no_button())
	assert_signal_not_emitted(_desk, "quit_requested")
	_press(_desk.pause_overlay().quit_button())
	_press(_desk.pause_overlay().yes_button())
	assert_signal_emitted(_desk, "quit_requested")


func test_the_witness_heading_shows_the_name_and_hovers_the_description() -> void:
	_commands().debug_jump(3, 1)
	var witness: String = _commands().current_encounter().witness_name
	assert_eq(witness, "Bersi, a crewman", "Freydis's witness")
	assert_eq(_system.witness_panel.heading_text(), "WITNESS Bersi", "D52: the name only")
	_system.witness_panel.heading_hover_area().mouse_entered.emit()
	assert_eq(_system.hover_label.shown_text(), witness, "D52: the full description on hover")


func test_the_hud_clock_shows_nothing_stale_after_the_day_ends() -> void:
	_play_to_dusk(2)
	assert_eq(_commands().phase(), RunState.DUSK)
	assert_eq(_system.hud.shown_time(), "", "no leftover time at dusk")
	_skip_dusk()
	assert_eq(_system.hud.shown_time(), "5:00", "the new day's clock at dawn")


func test_the_ending_puts_a_blank_line_between_its_sections() -> void:
	_play_to_dusk(3)
	_press(_system.phase_card.skip_button())
	var sections: PackedStringArray = _card().split("\n\n")
	assert_eq(sections.size(), 4, "outcome, rows, ledger, standing")
	var report: EndingReport = _commands().ending()
	assert_eq(sections[1].split("\n").size(), report.entries.size(), "one row per encounter")
	assert_eq(sections[2], report.promise_line)
	var expected: Array[String] = ScreenText.ending_sections(report, _rules())
	assert_eq(Array(sections), Array(expected), "the sections ScreenText composes")


func test_the_ending_follows_day_threes_dusk_and_play_again_restarts() -> void:
	_play_to_dusk(3)
	assert_eq(_commands().phase(), RunState.ENDING)
	_press(_system.phase_card.skip_button())
	var ending: String = _joined(ScreenText.ending_lines(_commands().ending(), _rules()))
	assert_eq(_card().replace("\n\n", "\n"), ending, "the slice ending (A8)")
	assert_string_contains(
		_card(), _text().standing_format % [_commands().feathers(), _commands().rank_name()]
	)
	assert_eq(_system.phase_card.next_button().text, _text().play_again)
	_press(_system.phase_card.next_button())
	assert_eq(_commands().phase(), RunState.DAWN)
	assert_eq(_commands().day_number(), 1)


func _commands() -> DeskCommands:
	return _desk.commands()


func _rules() -> SliceRules:
	return _commands().slice_rules()


func _text() -> DeskText:
	return _rules().text


func _card() -> String:
	return _system.phase_card.shown_text()


func _joined(lines: Array[String]) -> String:
	return "\n".join(lines)


## A press as the button's own signal sends it (the guard is tested with real clicks above).
func _press(button: Button) -> void:
	button.pressed.emit()


func _escape() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.physical_keycode = KEY_ESCAPE
	key.pressed = true
	_viewport.push_input(key)


## Plays every soul to its legal door until the dusk of `day` (or the ending after day 3).
func _play_to_dusk(day: int) -> void:
	var commands: DeskCommands = _commands()
	for _step: int in range(200):
		match commands.phase():
			RunState.DAWN:
				commands.begin_day()
			RunState.DESK:
				if commands.awaiting_next():
					commands.next_soul()
				else:
					commands.stamp(commands.current_encounter().legal_realm)
			RunState.DUSK:
				if commands.dusk_report().day >= day:
					return
				_skip_dusk()
			RunState.ENDING:
				return


func _skip_dusk() -> void:
	_press(_system.phase_card.skip_button())


## A move, a press and a release at `at`, pushed through the desk's viewport.
func _click(at: Vector2, double: bool) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	_viewport.push_input(motion)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		event.double_click = double and pressed
		_viewport.push_input(event)
