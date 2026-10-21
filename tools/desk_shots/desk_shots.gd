extends SceneTree
## Development only: plays the real desk with the slice data through real mouse events and saves a
## 1:1 screenshot after each step. Run it in a window at the base resolution:
##
##   godot --path . --resolution 480x270 -s tools/desk_shots/desk_shots.gd -- <output-folder>
##
## Each step is a mouse move or click pushed through the viewport, as a player's would be, and
## each step's outcome is checked; the run prints FAIL lines and exits 1 when one does not hold.

const DESK_SCENE := "res://scenes/desk/desk.tscn"

var _out: String = ""
var _desk: Desk = null
var _failures: int = 0


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	_desk = (load(DESK_SCENE) as PackedScene).instantiate() as Desk
	root.add_child(_desk)
	_run.call_deferred()


func _run() -> void:
	var system: DeskSystem = _desk.system()
	await _frames(3)
	await _shot("01_dawn")
	await _double_click_control(system.phase_card.next_button())
	_expect(_desk.commands().phase() == RunState.DAWN, "a double-click on Begin is ignored")
	await _wait(0.4)
	await _click_control(system.phase_card.next_button())
	_expect(_soul() == "Ulf", "Begin seats Ulf")
	await _shot("02_ulf")
	await _hover(system.body_chart.area("B2"))
	_expect(system.hover_label.shown_text() == "no wound, back", "an absence hovers its label")
	await _shot("03_hover_absence")
	await _click_control(system.claim_panel.area("C1"))
	_expect(system.claim_panel.area("C1").selected, "the first click selects")
	await _shot("04_selected_c1")
	await _click_control(system.law_panel.area("L1"))
	_expect(_desk.commands().threads().size() == 1, "the second click pins a thread")
	await _shot("05_law_thread")
	await _double_click_control(_door(&"valhalla"))
	_expect(system.stamp_prompt.question() == "Stamp Ulf to Valhalla?", "a door click asks")
	await _shot("06_stamp_prompt")
	await _double_click_control(system.stamp_prompt.confirm_button())
	_expect(_soul() == "Ulf", "a double-click on the confirm stamps nothing")
	await _shot("07_double_click_ignored")
	await _wait(0.4)
	await _click_control(system.stamp_prompt.confirm_button())
	_expect(_soul() == "Kolbeinn", "one deliberate click on the confirm stamps")
	await _shot("08_kolbeinn")
	await _click_control(system.body_chart.area("B1"))
	await _click_control(system.claim_panel.area("C1"))
	await _shot("09_red_thread")
	await _click_control(system.body_chart.area("B3"))
	await _click_control(system.law_panel.area("L3"))
	_expect(_desk.commands().threads().size() == 2, "two threads on Kolbeinn")
	await _shot("10_two_threads")
	await _click_control(system.claim_panel.area("C4"))
	await _click_control(system.law_panel.area("L1"))
	await _wait(3.1)
	_expect(system.caption_strip.shown_text() == "No seam.", "a no-seam pin says so")
	await _shot("11_no_seam")
	await _hover(_door(&"folkvangr"))
	await _shot("12_locked_door")
	await _click_control(_door(&"valhalla"))
	await _wait(0.4)
	await _click_control(system.stamp_prompt.confirm_button())
	_expect(_desk.commands().awaiting_next(), "the warning holds Kolbeinn (D48)")
	_expect(system.feather.visible and system.next_soul_button.visible, "feather and Next soul")
	await _shot("13_warning_holds_soul")
	await _click_control(system.feather)
	await _shot("14_feather_clicked")
	await _click_control(system.next_soul_button)
	_expect(_desk.commands().phase() == RunState.ENDING, "Next soul ends the one-day slice")
	await _shot("15_dusk")
	print("DESK SHOTS: %s" % ("PASS" if _failures == 0 else "%d FAILED" % _failures))
	quit(0 if _failures == 0 else 1)


func _expect(condition: bool, what: String) -> void:
	if not condition:
		_failures += 1
		print("FAIL: " + what)


func _soul() -> String:
	return _desk.system().soul.soul_name()


func _door(realm: StringName) -> Door:
	for door: Door in _desk.system().doors:
		if door.realm == realm:
			return door
	return null


func _hover(target: Control) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = target.get_global_rect().get_center()
	motion.global_position = motion.position
	root.push_input(motion)
	await _frames(2)


func _click_control(target: Control) -> void:
	await _hover(target)
	await _press(target.get_global_rect().get_center(), false)


func _double_click_control(target: Control) -> void:
	await _hover(target)
	await _press(target.get_global_rect().get_center(), false)
	await _press(target.get_global_rect().get_center(), true)


func _press(at: Vector2, double: bool) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		event.double_click = double and pressed
		root.push_input(event)
		await _frames(1)
	await _frames(2)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = _out.path_join(name + ".png")
	image.save_png(path)
	print("saved %s (%dx%d)" % [path, image.get_width(), image.get_height()])


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame
