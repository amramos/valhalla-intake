extends SceneTree
## Development only: rebuilds every content .tres under data/ from the evidence matrix's text
## (docs/plans/vertical-slice-matrix.md), with ResourceSaver so the files stay canonical text.
## The matrix is the source; this script is its typed transcription. Never shipped.
##
##   godot --headless --path . -s tools/content/build_content.gd

const Souls := preload("res://tools/content/content_souls.gd")
const Text := preload("res://tools/content/content_text.gd")

const FLAGS := ResourceSaver.FLAG_CHANGE_PATH
const DECREES: Array[Array] = [
	[
		"L1",
		(
			"Valhalla takes only those slain by a weapon in battle. "
			+ "Death by sickness, age or accident goes to Hel."
		)
	],
	["L2", "Whoever lies to the Gate goes to Hel, whatever else the Law says."],
	["L3", "Even so, a warrior without a weapon in hand goes to Hel."],
	["L4", "Even so, those who fled the battle go to Hel."],
	["L5", "Those who fell defending hearth and kin go to Fólkvangr, whatever I, III and IV say."],
]
const PLACES: Dictionary = {
	"chest": &"torso_front",
	"back": &"torso_back",
	"right hand": &"hand_right",
	"left hand": &"hand_left",
	"neck": &"neck",
	"legs": &"legs",
	"hem": &"hem",
}
const RED_CAPTION := "the body gives the lie."
const GREY_CAPTION := "one of them lies."


func _initialize() -> void:
	for folder: String in ["decrees", "encounters", "days"]:
		DirAccess.make_dir_recursive_absolute("res://data/%s" % folder)
	var decrees: Array[DecreeData] = []
	for row: Array in DECREES:
		var decree := DecreeData.new()
		decree.id = row[0]
		decree.text = row[1]
		decrees.append(_save(decree, "res://data/decrees/%s.tres" % String(row[0]).to_lower()))
	var souls: Dictionary = {}
	for spec: Dictionary in Souls.all():
		var encounter: EncounterData = _encounter(spec)
		souls[spec["id"]] = _save(encounter, "res://data/encounters/%s.tres" % spec["id"])
	var days: Array[DayData] = []
	for spec: Dictionary in Text.days():
		var day: DayData = _day(spec, decrees, souls)
		days.append(_save(day, "res://data/days/day_%d.tres" % day.day))
	var slice: SliceData = Text.slice()
	slice.days = days
	slice.returned_ignored = souls["hakon_ignored"]
	slice.returned_missed = souls["hakon_missed"]
	slice.fallback = souls["egil"]
	_save(slice, "res://data/slice.tres")
	quit()


func _encounter(spec: Dictionary) -> EncounterData:
	var encounter := EncounterData.new()
	encounter.id = StringName(spec["id"])
	encounter.soul_name = spec["name"]
	encounter.pronoun = spec["pronoun"]
	encounter.legal_realm = StringName(spec["legal"])
	encounter.worthy_realm = StringName(spec["worthy"])
	encounter.liar = spec["liar"]
	encounter.truth = spec["truth"]
	encounter.claim.assign(spec["claim"])
	encounter.witness_name = spec.get("witness_name", "")
	encounter.witness.assign(spec.get("witness", []))
	encounter.witness_note = spec.get("witness_note", "")
	encounter.plate_label = spec.get("plate", "")
	encounter.hel_marked = spec.get("hel_marked", false)
	encounter.returned = spec.get("returned", false)
	encounter.return_eligible = spec.get("return_eligible", false)
	encounter.red_herrings.assign(spec.get("herrings", []))
	for row: Array in spec["body"]:
		var fact := FactData.new()
		fact.id = row[0]
		fact.label = row[1]
		fact.view = &"back" if row[2] == "back" else &"front"
		fact.place = PLACES[row[2]]
		fact.resource_scene_unique_id = "fact_%s" % fact.id
		encounter.body.append(fact)
	var pair: Array = spec.get("cite", [])
	for row: Array in spec["seams"]:
		var seam := SeamData.new()
		seam.a = row[0]
		seam.b = row[1]
		match row[2]:
			"red":
				seam.kind = Seam.Kind.RED
				seam.liar = Seam.Liar.CLAIM
				seam.caption = RED_CAPTION
			"grey":
				seam.kind = Seam.Kind.GREY
				seam.liar = Seam.Liar.CLAIM
				seam.caption = GREY_CAPTION
			_:
				seam.kind = Seam.Kind.LAW
				seam.destination = StringName(row[3])
				seam.caption = row[4]
		if not pair.is_empty() and pair[0] == seam.a and pair[1] == seam.b:
			seam.pair_text = pair[2]
		seam.resource_scene_unique_id = "seam_%s_%s" % [seam.a, seam.b]
		encounter.seams.append(seam)
	for index: int in spec.get("mentor", []).size():
		encounter.mentor_steps.append(_mentor_step(spec, index))
	return encounter


## A2's steps: "body" lights every body fact, "body+claim" the claim too, "a|b" a pair,
## "door:<realm>" points at a door.
func _mentor_step(spec: Dictionary, index: int) -> MentorStepData:
	var row: Array = spec["mentor"][index]
	var step := MentorStepData.new()
	step.text = row[0]
	step.until = {"read": MentorStep.Until.READ, "pin": MentorStep.Until.PIN}.get(
		row[1], MentorStep.Until.STAMP
	)
	var lit: String = row[2]
	if lit.begins_with("door:"):
		step.door = StringName(lit.trim_prefix("door:"))
	elif lit.begins_with("body"):
		for fact: Array in spec["body"]:
			step.highlight.append(fact[0])
		if lit == "body+claim":
			for line: int in spec["claim"].size():
				step.highlight.append("C%d" % (line + 1))
	elif lit != "":
		step.highlight.assign(lit.split("|"))
	step.resource_scene_unique_id = "mentor_%d" % (index + 1)
	return step


func _day(spec: Dictionary, decrees: Array[DecreeData], souls: Dictionary) -> DayData:
	var day := DayData.new()
	day.day = spec["day"]
	day.quota = spec["quota"]
	day.clock_seconds = spec["clock"]
	day.doors_open.assign(spec["doors"])
	day.decrees.assign(decrees.slice(0, spec["decrees"]))
	day.citations = spec["citations"]
	day.huginn_answers = spec["huginn"]
	day.new_decree_ids.assign(spec["new_decrees"])
	day.new_doors.assign(spec["new_doors"])
	day.return_slot = spec["return_slot"]
	day.dusk_story = spec["story"]
	day.dawn_lines.assign(spec["dawn"])
	for id: String in spec["queue"]:
		day.encounters.append(souls[id])
	return day


func _save(resource: Resource, path: String) -> Resource:
	var error: Error = ResourceSaver.save(resource, path, FLAGS)
	if error != OK:
		push_error("can't save %s: %s" % [path, error_string(error)])
	# Load it back, so whatever refers to it saves a reference to the file, not a copy.
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
