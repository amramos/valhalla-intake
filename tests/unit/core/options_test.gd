extends GutTest
## The options (D37): text speed, reduce motion, volume and mute, saved in a config file and read
## back validated, so a missing, malformed or hand-edited file never breaks the game.

const PATH := "user://options_test.cfg"


func after_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)


func _write(text: String) -> void:
	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _values(options: Options) -> Array:
	return [options.text_speed, options.reduce_motion, options.volume_db, options.muted]


func test_the_text_speeds_set_the_characters_a_second() -> void:
	var options := Options.new()
	var speeds: Array[float] = []
	for speed: StringName in [Options.NORMAL, Options.FAST, Options.INSTANT, &"warp"]:
		options.text_speed = speed
		speeds.append(options.cps())
	assert_eq(speeds, [40.0, 80.0, INF, 40.0] as Array[float])


func test_a_missing_file_gives_the_defaults() -> void:
	assert_eq(_values(Options.load(PATH)), [&"normal", false, 0.0, false])


func test_saved_options_load_back() -> void:
	var options := Options.new()
	options.text_speed = Options.INSTANT
	options.reduce_motion = true
	options.volume_db = -12.5
	options.muted = true
	assert_true(options.save(PATH))
	assert_eq(_values(Options.load(PATH)), [&"instant", true, -12.5, true])


func test_a_malformed_file_gives_the_defaults() -> void:
	_write("[options\ntext_speed = = fast\nvolume_db = {{\n")
	assert_eq(_values(Options.load(PATH)), [&"normal", false, 0.0, false])
	# The engine logs the parse error itself; the game carries on with the defaults.
	assert_engine_error("ConfigFile parse error")


func test_each_invalid_value_falls_back_alone() -> void:
	_write(
		(
			'[options]\ntext_speed="warp"\nreduce_motion=true\nvolume_db=12.0\nmuted="yes"\n'
			+ '\n[other]\ntext_speed="fast"\n'
		)
	)
	assert_eq(_values(Options.load(PATH)), [&"normal", true, 0.0, false])


func test_the_volume_range_is_inclusive_and_whole_numbers_count() -> void:
	_write('[options]\ntext_speed="fast"\nvolume_db=-40\n')
	assert_eq(_values(Options.load(PATH)), [&"fast", false, -40.0, false])
	_write("[options]\nvolume_db=-40.5\n")
	assert_eq(Options.load(PATH).volume_db, 0.0)


func test_a_file_that_cannot_be_written_reports_false() -> void:
	var options := Options.new()
	assert_false(options.save("user://no_such_folder/deeper/options.cfg"))


func test_an_invalid_value_is_never_written() -> void:
	var options := Options.new()
	options.text_speed = &"warp"
	options.volume_db = NAN
	assert_true(options.save(PATH))
	assert_eq(_values(Options.load(PATH)), [&"normal", false, 0.0, false])
