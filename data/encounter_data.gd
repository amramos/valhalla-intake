class_name EncounterData
extends Resource
## One authored encounter (the evidence matrix's slot): body, claim, witness, seams and both
## destinations. Claim lines become C1, C2…; witness lines W1, W2….

@export var id: StringName = &""
@export var soul_name: String = ""
## "him" or "her".
@export var pronoun: String = "him"
@export var body: Array[FactData] = []
@export var claim: Array[String] = []
@export var witness_name: String = ""
@export var witness: Array[String] = []
## Shown in an empty witness panel (D46); "" hides the panel.
@export var witness_note: String = ""
@export var seams: Array[SeamData] = []
## Pairs that look like seams but resolve innocent, as "B3|C2" (D24). Data for the authoring
## check only: a red herring is any pair that isn't a seam.
@export var red_herrings: Array[String] = []
@export var legal_realm: StringName = &""
@export var worthy_realm: StringName = &""
@export var liar: bool = false
@export var hel_marked: bool = false
@export var plate_label: String = ""
@export var returned: bool = false
@export var return_eligible: bool = false
## The guided steps on a tutorial soul (D16); empty on unguided souls.
@export var mentor_steps: Array[MentorStepData] = []
## The recap: what really happened.
@export_multiline var truth: String = ""


func to_core() -> Encounter:
	var encounter := Encounter.new()
	encounter.id = id
	encounter.soul_name = soul_name
	encounter.pronoun = pronoun
	for fact: FactData in body:
		encounter.items.append(fact.to_core())
	for index: int in claim.size():
		encounter.items.append(
			EvidenceItem.make("C%d" % (index + 1), EvidenceItem.Group.CLAIM, claim[index])
		)
	for index: int in witness.size():
		encounter.items.append(
			EvidenceItem.make("W%d" % (index + 1), EvidenceItem.Group.WITNESS, witness[index])
		)
	encounter.witness_name = witness_name
	encounter.witness_note = witness_note
	for seam: SeamData in seams:
		encounter.seams.append(seam.to_core())
	encounter.legal_realm = legal_realm
	encounter.worthy_realm = worthy_realm
	encounter.liar = liar
	encounter.hel_marked = hel_marked
	encounter.plate_label = plate_label
	encounter.returned = returned
	encounter.return_eligible = return_eligible
	for step: MentorStepData in mentor_steps:
		encounter.mentor_steps.append(step.to_core())
	encounter.truth = truth
	return encounter
