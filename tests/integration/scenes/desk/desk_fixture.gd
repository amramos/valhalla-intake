extends RefCounted
## A timed day-3 desk for the integration tests: one soul with every kind of thread (a grey seam
## between claim and witness, a red seam from the body to the witness, law threads from the body
## and from the claim), Huginn on the desk, citations on, and a second soul behind it.

const DECREES: Array[String] = [
	(
		"Valhalla takes only those slain by a weapon in battle. "
		+ "Death by sickness, age or accident goes to Hel."
	),
	"Whoever lies to the Gate goes to Hel, whatever else the Law says.",
	"Even so, a warrior without a weapon in hand goes to Hel.",
	"Even so, those who fled the battle go to Hel.",
	"Those who fell defending hearth and kin go to Fólkvangr, whatever L1, L3 and L4 say.",
]
const CLOCK_SECONDS := 300.0


static func commands() -> DeskCommands:
	var day := DayRules.new()
	day.day = 3
	day.quota = 1
	day.clock_seconds = CLOCK_SECONDS
	day.doors_open = [Realm.VALHALLA, Realm.HEL, Realm.FOLKVANGR]
	day.citations = true
	day.huginn_answers = 2
	for index: int in range(DECREES.size()):
		day.decrees.append(
			EvidenceItem.make("L%d" % (index + 1), EvidenceItem.Group.LAW, DECREES[index])
		)
	var first := Encounter.new()
	first.id = &"fixture_first"
	first.soul_name = "Asgaut"
	first.witness_name = "Orm"
	first.legal_realm = Realm.HEL
	first.worthy_realm = Realm.HEL
	first.liar = true
	first.items = [
		_body("B1", "no wound, front", &"front", &"torso_front"),
		_body("B2", "no wound, back", &"back", &"torso_back"),
		_body("B3", "nothing in hand", &"front", &"hand_right"),
		_body("B4", "neck, broken", &"front", &"neck"),
		EvidenceItem.make("C1", EvidenceItem.Group.CLAIM, "Held the shield-wall."),
		EvidenceItem.make("C2", EvidenceItem.Group.CLAIM, "Held my own door."),
		EvidenceItem.make("C3", EvidenceItem.Group.CLAIM, "Fell at dawn."),
		EvidenceItem.make("W1", EvidenceItem.Group.WITNESS, "He ran at dawn."),
		EvidenceItem.make("W2", EvidenceItem.Group.WITNESS, "A spear in the chest."),
		EvidenceItem.make("W3", EvidenceItem.Group.WITNESS, "I saw it all."),
	]
	first.seams = [
		Seam.make("C1", "W1", Seam.Kind.GREY, Seam.Liar.WITNESS, &"", "one of them lies."),
		Seam.make("B1", "W2", Seam.Kind.RED, Seam.Liar.WITNESS, &"", "the body gives the lie."),
		Seam.make("B3", "L3", Seam.Kind.LAW, Seam.Liar.NONE, Realm.HEL, "L3 sends him to Hel."),
		Seam.make(
			"C2", "L5", Seam.Kind.LAW, Seam.Liar.NONE, Realm.FOLKVANGR, "L5 sends him to Fólkvangr."
		),
	]
	var second := Encounter.new()
	second.id = &"fixture_second"
	second.soul_name = "Second"
	second.legal_realm = Realm.VALHALLA
	second.worthy_realm = Realm.VALHALLA
	second.items = [_body("B1", "wound, front", &"front", &"torso_front")]
	var result := DeskCommands.new()
	var days: Array[DayRules] = [day]
	result.start_run(days, [[first, second]], SliceRules.new(), {})
	return result


static func _body(id: String, label: String, view: StringName, place: StringName) -> EvidenceItem:
	return EvidenceItem.make(id, EvidenceItem.Group.BODY, label, view, place)
