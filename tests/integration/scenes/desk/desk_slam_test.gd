extends GutTest
## The slam as the player sees it (D14, D15, D54-D56): the desk dims while the stamp is raised; at
## the impact the stamp squashes, the writ and the stamp flash and the writ dents, the veil deepens,
## ink bursts outward from the block and, as the stamp lifts, a shockwave leaves the ink; all timed,
## the same for a hero and a liar. The stamped
## soul's sheets, slab, thread and note stay on the desk through the slam, and the next soul's come
## in when it releases, the sheets sliding up into place with the walk-in.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const THEME := preload("res://scenes/desk/desk_theme.tres")
const Palette := preload("res://tests/unit/entities/desk_palette.gd")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
## Real time is a little late under a loaded test runner.
const SLACK := 0.2
const LAST_WORD := "the last word on Asgaut"

var _desk: Desk = null
var _system: DeskSystem = null


## Timed, never counted in frames: stepped by elapsed seconds from the impact, the writ and the
## stamp flash over the choice's 0.25 veil to 0.03 s, then the veil is 0.55 until the lift at
## 0.15 s; the burst is 3 px out (Parchment 2) to 0.03 s, 6 px (Fog 2) to 0.06 s and 9 px (Fog 1)
## to 0.09 s; the squash and the writ's 1 px dent hold 0.06 s; and the shockwave is 21x21 (ink) to
## 0.20 s and 27x27 (Fog 2) to 0.25 s (D56 and the critic's stamp polish on #22).
func test_the_impact_marks_last_their_time_not_their_frames() -> void:
	_open(Fixture.instant())
	var prompt: StampPrompt = _system.stamp_flow.stamp_prompt
	var face: StampFace = prompt.get_node("Face") as StampFace
	var writ: Writ = prompt.writ()
	var marks: ImpactMarks = prompt.marks()
	prompt.ask("Asgaut", &"hel")
	prompt.stamp_down(&"hel")
	var slam: Tween = prompt.slam(&"hel")
	slam.pause()
	var seen: Array = []
	var last: float = 0.0
	for at: float in [0.0, 0.02, 0.04, 0.07, 0.1, 0.14, 0.16, 0.21, 0.26]:
		slam.custom_step(at - last)
		last = at
		seen.append(
			[
				at,
				face.block_height(),
				face.visible,
				marks.veil_alpha(),
				marks.burst_stage(),
				marks.ring_stage(),
				face.is_flashing(),
				writ.is_flashing(),
				writ.position.y
			]
		)
	var expected: Array = [
		[0.0, 26, true, 0.25, 1, 0, true, true, 1.0],
		[0.02, 26, true, 0.25, 1, 0, true, true, 1.0],
		[0.04, 26, true, 0.55, 2, 0, false, false, 1.0],
		[0.07, 28, true, 0.55, 3, 0, false, false, 0.0],
		[0.1, 28, true, 0.55, 0, 0, false, false, 0.0],
		[0.14, 28, true, 0.55, 0, 0, false, false, 0.0],
		[0.16, 28, false, 0.0, 0, 1, false, false, 0.0],
		[0.21, 28, false, 0.0, 0, 2, false, false, 0.0],
		[0.26, 28, false, 0.0, 0, 0, false, false, 0.0],
	]
	assert_eq(seen, expected, "flash, dent, burst, squash, veil and shockwave on their times")
	assert_true(prompt.is_inked(), "the ink stays")


## The critic's stamp polish (#22): the hit is the brightest instant, not the lift. At the impact
## the writ is Parchment 2 and every tone of the stamp a band lighter, over the choice's veil, with
## the doors yielding; at the lift's shockwave the writ is its own Parchment 1 again.
func test_the_hit_is_brighter_than_the_lift() -> void:
	_open(Fixture.instant())
	var prompt: StampPrompt = _system.stamp_flow.stamp_prompt
	var face: StampFace = prompt.get_node("Face") as StampFace
	var writ: Writ = prompt.writ()
	prompt.ask("Asgaut", &"hel")
	await wait_process_frames(2)
	var resting: float = _brightness(face.drawn_colors())
	prompt.stamp_down(&"hel")
	var slam: Tween = prompt.slam(&"hel")
	slam.pause()
	await wait_process_frames(2)
	var hit: Array[Color] = face.drawn_colors()
	assert_eq(Palette.strays(hit), [] as Array[String], "the flash is palette colours")
	assert_gt(_brightness(hit), resting, "the stamp flashes brighter than it stands")
	var light: Color = THEME.get_color(&"pin_highlight", &"DeskPalette")
	assert_eq(writ.sheet_color(), light, "the writ flashes Parchment 2")
	var flash: float = writ.sheet_color().get_luminance()
	assert_eq(_door(&"hel").z_index, 0, "the doors yield at the hit")
	slam.custom_step(StampPrompt.LIFT_SECONDS + 0.001)
	assert_true(prompt.is_ringing(), "the lift's shockwave frame")
	assert_false(writ.is_flashing(), "the flash is over by then")
	assert_lt(
		writ.sheet_color().get_luminance(), flash, "the writ is dimmer at the lift than at the hit"
	)


## D56: the choice dims the desk to 0.25 under the writ, the stamp, its label and the doors; the
## veil goes with the stamp, steps back under the pause, and never shows under reduce motion, nor
## does the impact's flash, while the stamp's shadow, the squash, the dent, the burst and the
## shockwave stay as cues.
func test_the_raised_stamp_dims_the_desk_but_the_doors_the_writ_and_the_stamp() -> void:
	_open(Fixture.instant())
	_system.finish_tellings()
	var prompt: StampPrompt = _system.stamp_flow.stamp_prompt
	var veil: ColorRect = prompt.get_node("Dim") as ColorRect
	var marks: ImpactMarks = prompt.marks()
	_door(&"hel").press()
	assert_true(prompt.is_dimming(), "the choice dims the desk")
	assert_eq(marks.veil_alpha(), StampPrompt.CHOICE_DIM, "at 0.25")
	assert_eq(veil.get_global_rect(), Rect2(0, 0, 480, 270), "the whole screen")
	var night: Color = THEME.get_color(&"ink", &"DeskPalette")
	assert_eq(veil.color, Color(night, StampPrompt.CHOICE_DIM), "in Night 0")
	var lifted: Array[CanvasItem] = [
		prompt.get_node("WritSlot"), prompt.get_node("Face"), prompt.get_node("Question")
	]
	lifted.append_array(_system.doors)
	for item: CanvasItem in lifted:
		assert_gt(item.z_index, veil.z_index, "%s above the veil" % item.name)
	_desk.toggle_pause()
	assert_false(prompt.is_dimming(), "the pause covers the desk: the veil steps back")
	assert_eq(_system.doors[0].z_index, 0, "and the doors under the pause")
	_desk.pause_overlay().resume_button().pressed.emit()
	assert_true(prompt.is_dimming(), "resumed, the choice is dimmed again")
	prompt.withdraw()
	assert_false(prompt.is_dimming(), "the stamp put down lifts the veil")
	for item: CanvasItem in lifted:
		assert_eq(item.z_index, 0, "%s back in its place" % item.name)
	prompt.reduce_motion = true
	prompt.ask("Asgaut", &"hel")
	assert_false(prompt.is_dimming(), "reduce motion: the raised stamp is the cue (D37)")
	assert_true(prompt.writ().shadow().has_area(), "with its shadow on the writ")
	prompt.stamp_down(&"hel")
	var slam: Tween = prompt.slam(&"hel")
	slam.pause()
	assert_false(prompt.is_dimming(), "nor at the impact (D55)")
	assert_eq(_door(&"hel").z_index, 0, "the doors stay in their place")
	assert_false(prompt.writ().is_flashing(), "no flash on the writ")
	assert_false((prompt.get_node("Face") as StampFace).is_flashing(), "nor on the stamp")
	assert_eq(prompt.writ().position.y, 1.0, "the dent stays, a state cue")
	assert_eq(marks.burst_stage(), 1, "the burst stays, a state cue")
	assert_eq(
		(prompt.get_node("Face") as StampFace).block_height(),
		StampFace.SQUASH_HEIGHT,
		"and the squash"
	)
	slam.custom_step(StampPrompt.LIFT_SECONDS + 0.001)
	assert_eq(marks.ring_stage(), 1, "and the shockwave")


## D55, D56: the impression is the stamp's own face (its bold 15x15 glyph in a 19x19 ink box on a
## 90x20 writ whose name still reads); the burst flies out 3 px, 6 px then 9 px from the block, each
## stage wholly beyond the last, in palette colours and below every door's glyph; the shockwave
## is centred on the ink box.
func test_the_impression_the_burst_and_the_shockwave_in_place() -> void:
	_open(Fixture.instant())
	var prompt: StampPrompt = _system.stamp_flow.stamp_prompt
	var marks: ImpactMarks = prompt.marks()
	var writ: Writ = prompt.writ()
	assert_eq(writ.get_global_rect(), Rect2(187, 80, 90, 20), "the writ under the doors")
	assert_eq(
		StampFace.THICK_SPAN, PixelGlyph.SIZE * StampFace.GLYPH_SCALE + 1, "the bold glyph is 15x15"
	)
	var name_end: int = int(Writ.NAME_AT.x) + Writ.NAME_MAX_WIDTH
	assert_lt(name_end, Writ.INK_BOX.position.x, "names clear the box")
	var box := Rect2(writ.global_position + Vector2(Writ.INK_BOX.position), Vector2(19, 19))
	prompt.ask("Asgaut", &"hel")
	prompt.stamp_down(&"hel")
	var slam: Tween = prompt.slam(&"hel")
	slam.pause()
	var block := Rect2(
		(prompt.get_node("Face") as Control).global_position, Vector2(StampFace.SIZE)
	)
	block = Rect2(
		block.position + Vector2(0, StampFace.HANDLE_HEIGHT),
		Vector2(StampFace.SIZE.x, StampFace.BLOCK_HEIGHT)
	)
	var colours: Array[Color] = []
	var stage_at: Array[float] = [
		0.0, 0.0, StampPrompt.BURST_MID_SECONDS + 0.001, StampPrompt.BURST_FAR_SECONDS + 0.001
	]
	var elapsed: float = 0.0
	var farthest: int = 0
	for stage: int in [1, 2, 3]:
		slam.custom_step(stage_at[stage] - elapsed)
		elapsed = stage_at[stage]
		assert_eq(marks.burst_stage(), stage, "stage %d on its time" % stage)
		var pixels: Array[Rect2] = marks.burst_pixels()
		assert_eq(pixels.size(), 16, "eight streaks of two pixels")
		var reach: int = ImpactMarks.BURST_REACH[stage]
		var nearest: int = reach
		for pixel: Rect2 in pixels:
			assert_false(block.intersects(pixel), "outside the block")
			assert_true(block.grow(reach).encloses(pixel), "within %d px of it" % reach)
			assert_gte(pixel.position.y, 60.0, "below every door's glyph")
			nearest = mini(nearest, _distance(block, pixel.position))
		assert_gt(nearest, farthest, "stage %d lies wholly beyond the one before" % stage)
		farthest = reach
		colours.append(marks.burst_color())
	slam.custom_step(StampPrompt.LIFT_SECONDS + 0.001 - elapsed)
	assert_eq(marks.ring_rect(), box.grow(2), "the shockwave starts 23x23 round the box")
	colours.append(marks.ring_color())
	slam.custom_step(StampPrompt.WAVE_WIDE_SECONDS - StampPrompt.LIFT_SECONDS)
	assert_eq(marks.ring_rect(), box.grow(5), "and widens to 29x29")
	colours.append(marks.ring_color())
	assert_eq(Palette.strays(colours), [] as Array[String], "palette colours only")
	var light: Color = THEME.get_color(&"pin_highlight", &"DeskPalette")
	var fog: Color = THEME.get_color(&"text_muted", &"DeskPalette")
	var faint: Color = THEME.get_color(&"glyph_dim", &"DeskPalette")
	assert_eq(
		colours,
		[light, fog, faint, fog, faint],
		"burst Parchment 2, Fog 2, Fog 1; wave Fog 2 then Fog 1, never Ink"
	)


## The critic's stamp polish (#22): the stamp travels visibly. Raised, it stands 8 px over the
## paper and its 1 px Night 1 shadow lies on the writ just above the row its face will land on
## (clear of the paper's own edge shadow); at the impact its face is down and the shadow is gone.
func test_the_raised_stamp_stands_over_its_shadow() -> void:
	_open(Fixture.instant())
	_system.finish_tellings()
	var prompt: StampPrompt = _system.stamp_flow.stamp_prompt
	var face: StampFace = prompt.get_node("Face") as StampFace
	var writ: Writ = prompt.writ()
	assert_gte(StampPrompt.CONTACT_Y - StampPrompt.RAISED_Y, 8.0, "8 px of travel at least")
	_door(&"hel").press()
	await wait_seconds(StampPrompt.RISE_SECONDS + SLACK)
	assert_eq(face.position.y, StampPrompt.RAISED_Y, "raised")
	var shadow := Rect2(writ.global_position + Vector2(writ.shadow().position), writ.shadow().size)
	assert_eq(shadow.size, Vector2(24, 1), "a 1 px shadow, 2 px narrower than the block each side")
	var raised_face: float = face.get_global_rect().end.y - 1
	assert_eq(shadow.position.y - raised_face, 7.0, "7 px under the raised stamp's face")
	await wait_process_frames(2)
	var night: Color = THEME.get_color(&"night", &"DeskPalette")
	assert_eq(writ.drawn_ink().get(Vector2i(writ.shadow().position)), night, "in Night 1")
	_system.stamp_flow.stamp_prompt.confirm_button().arm_now()
	_system.stamp_flow.stamp_prompt.confirm_button().pressed.emit()
	assert_false(writ.shadow().has_area(), "the stamp on the paper covers its shadow")
	var contact_face: float = face.get_global_rect().end.y - 1
	assert_eq(contact_face, shadow.position.y + 1, "its face lands on the row under the shadow")


## D55: the thud starts on the impact's frame, with the squash, never before it.
func test_the_thud_starts_on_the_frame_the_stamp_lands() -> void:
	_open(Fixture.instant())
	var face: StampFace = _system.stamp_flow.stamp_prompt.get_node("Face") as StampFace
	var thud: AudioStreamPlayer = _system.stamp_flow.thud_player
	_stamp(&"hel")
	var first_heard: int = -1
	while _desk.gate().is_slamming() and first_heard < 0:
		await get_tree().process_frame
		if thud.playing:
			first_heard = face.block_height()
	assert_eq(first_heard, StampFace.SQUASH_HEIGHT, "first heard on the frame the stamp squashes")


## In the running desk: the squash comes at the impact, the ring after the stamp lifts, the desk
## yields and comes back, and all are over before the walk.
func test_the_impact_squashes_the_stamp_and_the_lift_rings_the_ink_box() -> void:
	_open(Fixture.instant())
	var prompt: StampPrompt = _system.stamp_flow.stamp_prompt
	var face: StampFace = prompt.get_node("Face") as StampFace
	_stamp(&"hel")
	var timeline: Dictionary = await _slam_timeline()
	assert_eq(timeline["height"], [26, 28], "squashed once")
	assert_eq(timeline["dent"], [1.0, 0.0], "the writ dented once and sprang back")
	assert_true(_in_order(timeline["burst"], [1, 2, 3, 0]), "burst out stage by stage, then gone")
	assert_eq(timeline["ring"], [1, 2, 0], "the shockwave, once, gone by the walk")
	assert_eq(timeline["veil"], [0.55, 0.0], "the veil deepened after the flash and lifted")
	assert_false(face.visible, "the stamp has lifted")
	assert_true(prompt.is_inked(), "the ink stays")


## D14: nothing in the slam differs with the truth. A liar and a hero stamped to the same door get
## the same squash, the same ring, the same ink and the same window.
func test_the_slam_is_the_same_for_a_liar_and_a_hero() -> void:
	var timelines: Array = []
	for liar: bool in [true, false]:
		_open(Fixture.instant(), Fixture.matched(liar))
		_stamp(&"hel")
		timelines.append(await _slam_timeline())
		_desk.queue_free()
		await wait_process_frames(1)
	assert_eq(timelines[0], timelines[1], "the liar's slam and the hero's are one slam")
	assert_eq(timelines[0]["height"], [26, 28], "both squash, once")
	assert_eq(timelines[0]["dent"], [1.0, 0.0], "both dent the writ")
	assert_true(_in_order(timelines[0]["burst"], [1, 2, 3, 0]), "both burst")
	assert_eq(timelines[0]["ring"], [1, 2, 0], "both send the shockwave")
	assert_eq(timelines[0]["veil"], [0.55, 0.0], "and both deepen the veil")


## The critic's case: the stamped soul's evidence used to vanish under the slam, so Ulf's slip sat
## beside Kolbeinn's sheets. It stays through the slam and leaves when the slam releases.
func test_the_stamped_souls_evidence_stays_until_the_slam_releases() -> void:
	_open(Fixture.instant())
	var claim_home: Vector2 = _system.claim_panel.position
	_pin("B1", "W2")
	var strip: CaptionStrip = _system.caption_strip
	strip.take_over(LAST_WORD)
	_stamp(&"hel")
	assert_false(_desk.commands().awaiting_next(), "Asgaut's legal stamp holds nothing")
	assert_eq(_system.soul.soul_name(), "Second", "core seated the next soul")
	assert_lt(_system.soul.figure().get_global_rect().end.x, 0.0, "who waits off-screen")
	assert_true(_system.claim_panel.has_item("C1"), "Asgaut's claim stays on the desk")
	assert_true(_system.body_chart.has_item("B4"), "and his body on the slab")
	assert_eq(strip.shown_text(), LAST_WORD, "and the note")
	assert_eq(_threads(), 1, "and his thread")
	await wait_seconds(StampFlow.SLAM_SECONDS - 0.15)
	assert_true(_system.claim_panel.has_item("C1"), "all through the slam")
	await wait_seconds(0.2)
	assert_false(_desk.gate().is_slamming(), "the slam released")
	assert_false(_system.claim_panel.has_item("C1"), "Asgaut's claim has left")
	assert_false(_system.body_chart.has_item("B4"), "and his body")
	assert_true(_system.body_chart.has_item("B1"), "the next soul's body is on the slab")
	assert_ne(strip.shown_text(), LAST_WORD, "the note was cleared")
	assert_eq(_threads(), 0, "his thread is gone")
	await wait_seconds(DeskTelling.SLIDE_SECONDS + SLACK)
	assert_eq(_system.claim_panel.position, claim_home, "the sheet slid into its place")


## The review's case: with the next soul's tale not yet begun, the day clock ran through the slam.
## It waits through the slam window (D5) and runs again once the next soul's evidence is in.
func test_the_day_clock_waits_through_the_slam() -> void:
	_open(Fixture.instant())
	_stamp(&"hel")
	assert_false(_desk.commands().awaiting_next(), "an unheld stamp")
	var before: float = _desk.commands().time_left()
	_system._process(5.0)
	assert_eq(_desk.commands().time_left(), before, "no time passes in the slam window")
	await wait_seconds(StampFlow.SLAM_SECONDS - 0.15)
	assert_eq(_desk.commands().time_left(), before, "all through it")
	await wait_seconds(0.25)
	assert_false(_desk.gate().is_slamming(), "the slam released")
	_system.finish_tellings()
	var after: float = _desk.commands().time_left()
	_system._process(5.0)
	assert_eq(_desk.commands().time_left(), after - 5.0, "the clock runs again")


## The critic's case: Kolbeinn's guided step lit C1-C4 on Ulf's sheet, which still lay on the desk
## through the slam, while her bubble still said Ulf's step. Through the slam no step shows and no
## line is lit by one; after the release the new soul's step shows.
func test_no_guided_step_lights_the_old_sheet_during_the_slam() -> void:
	_open(Fixture.instant(), SliceLoader.load_slice())
	assert_eq(_system.soul.soul_name(), "Ulf")
	_stamp(&"valhalla")
	assert_eq(_system.soul.soul_name(), "Kolbeinn", "core seated the next soul")
	var step: MentorStep = _desk.commands().mentor_step()
	assert_not_null(step, "Kolbeinn is guided too")
	var lit: Array[String] = []
	var bubbles: Array[String] = []
	while _desk.gate().is_slamming():
		for index: int in range(1, 5):
			var line: PinSelectable = _system.claim_panel.area("C%d" % index)
			if line != null and line.lit and not lit.has(line.item_id):
				lit.append(line.item_id)
		var shown: String = _system.mentor_bubble.shown_text()
		if shown != "" and not bubbles.has(shown):
			bubbles.append(shown)
		await get_tree().process_frame
	assert_eq(lit, [] as Array[String], "no claim line is lit through the slam")
	assert_eq(bubbles, [] as Array[String], "and her bubble shows no step, old or new")
	await wait_process_frames(2)
	assert_eq(_system.mentor_bubble.shown_text(), step.text, "after the release her new step shows")


func test_the_new_sheets_slide_up_with_the_walk_in_and_not_under_reduce_motion() -> void:
	for still: bool in [false, true]:
		var options: Options = Fixture.instant()
		options.reduce_motion = still
		_open(options)
		var home: Vector2 = _system.claim_panel.position
		_stamp(&"hel")
		await wait_seconds(StampFlow.SLAM_SECONDS + 0.05)
		var offset: float = _system.claim_panel.position.y - home.y
		if still:
			assert_eq(offset, 0.0, "reduce motion: the sheets are in place at once (D37)")
		else:
			assert_gt(offset, 0.0, "the sheet rises from below")
			assert_lte(offset, float(DeskTelling.SLIDE_PX), "from 6 px below at most")
		_desk.queue_free()
		await wait_process_frames(1)


func test_a_restart_in_the_slam_leaves_no_evidence_waiting() -> void:
	_open(Fixture.instant())
	var claim_home: Vector2 = _system.claim_panel.position
	_stamp(&"hel")
	_system.restart()
	await wait_seconds(StampFlow.SLAM_SECONDS + SLACK)
	assert_eq(_system.claim_panel.position, claim_home, "no slide left half done")
	_system.phase_card.next_button().pressed.emit()
	assert_eq(_system.soul.soul_name(), "Asgaut", "the new run seats its first soul")
	assert_true(_system.claim_panel.has_item("C1"), "with his evidence at once")


func _open(options: Options, commands: DeskCommands = null) -> void:
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(commands if commands != null else Fixture.commands())
	_desk.use_options(options)
	add_child_autofree(_desk)
	_system = _desk.system()
	_system.phase_card.next_button().pressed.emit()


## Each part of the slam as it changed, read at the start of every frame until the window opens
## again, with repeats dropped and each part's resting state before it first changed left out (a
## slow first frame may already be past it): the block's height, the burst, the shockwave, the
## veil (resting at the choice's 0.25), the ink and the window.
func _slam_timeline() -> Dictionary:
	var prompt: StampPrompt = _system.stamp_flow.stamp_prompt
	var face: StampFace = prompt.get_node("Face") as StampFace
	var marks: ImpactMarks = prompt.marks()
	var parts: Dictionary = {
		"height": [], "dent": [], "burst": [], "ring": [], "veil": [], "ink": [], "window": []
	}
	while _desk.gate().is_slamming():
		await get_tree().process_frame
		_note(parts["height"], face.block_height(), StampFace.BLOCK_HEIGHT)
		_note(parts["dent"], prompt.writ().position.y, 0.0)
		_note(parts["burst"], marks.burst_stage(), 0)
		_note(parts["ring"], marks.ring_stage(), 0)
		_note(parts["veil"], marks.veil_alpha(), StampPrompt.CHOICE_DIM)
		_note(parts["ink"], prompt.writ().inked_glyph(), &"")
		_note(parts["window"], _desk.gate().is_slamming(), true)
	return parts


## How many pixels `pixel` lies outside `block` (0 inside), counting diagonals as one step.
func _distance(block: Rect2, pixel: Vector2) -> int:
	var dx: float = maxf(block.position.x - pixel.x, pixel.x - (block.end.x - 1))
	var dy: float = maxf(block.position.y - pixel.y, pixel.y - (block.end.y - 1))
	return maxi(0, int(maxf(dx, dy)))


## True when `seen` starts and ends as `full` does and skips none of its order: a stage a slow frame
## missed may be absent, but none comes early or twice.
func _in_order(seen: Array, full: Array) -> bool:
	if seen.is_empty() or seen.front() != full.front() or seen.back() != full.back():
		return false
	var at: int = 0
	for value: Variant in seen:
		at = full.find(value, at)
		if at < 0:
			return false
		at += 1
	return true


## The mean luminance of `colours`.
func _brightness(colours: Array[Color]) -> float:
	var total: float = 0.0
	for colour: Color in colours:
		total += colour.get_luminance()
	return total / maxf(1.0, float(colours.size()))


func _note(changes: Array, value: Variant, resting: Variant) -> void:
	if changes.is_empty() and value == resting:
		return
	if changes.is_empty() or changes.back() != value:
		changes.append(value)


func _threads() -> int:
	var count: int = 0
	for child: Node in _system.thread_layer.get_children():
		if child is ThreadLine and not child.is_queued_for_deletion():
			count += 1
	return count


func _pin(a: String, b: String) -> void:
	_system.finish_tellings()
	_area(a).press()
	_area(b).press()


func _area(item_id: String) -> PinSelectable:
	if _system.body_chart.has_item(item_id):
		return _system.body_chart.area(item_id)
	for panel: EvidencePanel in [_system.claim_panel, _system.witness_panel, _system.law_panel]:
		if panel.has_item(item_id):
			return panel.area(item_id)
	return null


func _stamp(realm: StringName) -> void:
	_system.finish_tellings()
	for door: Door in _system.doors:
		if door.realm == realm:
			door.press()
	_system.stamp_flow.stamp_prompt.confirm_button().arm_now()
	_system.stamp_flow.stamp_prompt.confirm_button().pressed.emit()


func _door(realm: StringName) -> Door:
	for door: Door in _system.doors:
		if door.realm == realm:
			return door
	return null
