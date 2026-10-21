class_name SliceData
extends Resource
## The slice: its days, the returned-soul variants and every tunable (D10, D23, D29, D35, D40).

@export var days: Array[DayData] = []
@export_group("Return arc (D2)")
## Slot 10 when the return-eligible soul went to Hel after its seam was pinned.
@export var returned_ignored: EncounterData = null
## Slot 10 when it went to Hel with its seam never pinned.
@export var returned_missed: EncounterData = null
## Slot 10 when it was not stamped to Hel.
@export var fallback: EncounterData = null
@export_group("Feathers")
@export var start_feathers: int = 0
@export var quota_met_reward: int = 0
@export var quota_short_cost: int = 0
@export var citation_cost: int = 0
@export var daily_loss_cap: int = 0
@export var demote_refill: int = 0
@export var huginn_extra_cost: int = 0
@export var hel_reward: int = 0
@export var rank_names: Array[String] = []
@export_group("Clock")
@export var no_seam_seconds: float = 0.0
@export var huginn_seconds: float = 0.0
@export var clock_warning_seconds: float = 0.0
@export_group("Ending")
@export var tide_threshold: int = 0
@export var hollow_threshold: int = 0
@export_group("Desk text (matrix section A)")
@export var desk_text: DeskTextData = null
@export var recap_agree_format: String = ""
@export var recap_legal_format: String = ""
@export var recap_mercy_format: String = ""
@export var recap_neither_format: String = ""
@export var recap_uncertain_format: String = ""
@export var recap_never_line: String = ""
@export var ledger_open_format: String = ""
@export var ledger_kept_format: String = ""
@export var ledger_broken_format: String = ""
@export var ledger_lapsed_format: String = ""
@export_group("The mentor (A2)")
@export var mentor_mercy_warning_format: String = ""
@export var mentor_illegal_warning_format: String = ""
@export var mentor_mercy_format: String = ""
@export var mentor_liar_format: String = ""
@export var mentor_honest_format: String = ""
@export var mentor_promise_format: String = ""
@export var mentor_grey_line: String = ""
@export var mentor_grey_huginn_line: String = ""
@export var mentor_tide_line: String = ""
@export var mentor_tide_suffix: String = ""
@export_group("Law and desk text")
@export var liar_decree_id: String = ""
@export var liar_realm: StringName = &""
@export var huginn_claim_answer: String = ""
@export var huginn_witness_answer: String = ""
@export var citation_format: String = ""
@export var threaded_line: String = ""
@export var returned_format: String = ""
@export var hel_offer_format: String = ""


func rules_to_core() -> SliceRules:
	var rules := SliceRules.new()
	rules.start_feathers = start_feathers
	rules.quota_met_reward = quota_met_reward
	rules.quota_short_cost = quota_short_cost
	rules.citation_cost = citation_cost
	rules.daily_loss_cap = daily_loss_cap
	rules.demote_refill = demote_refill
	rules.huginn_extra_cost = huginn_extra_cost
	rules.hel_reward = hel_reward
	rules.rank_names.assign(rank_names)
	rules.no_seam_seconds = no_seam_seconds
	rules.huginn_seconds = huginn_seconds
	rules.clock_warning_seconds = clock_warning_seconds
	rules.tide_threshold = tide_threshold
	rules.hollow_threshold = hollow_threshold
	if desk_text != null:
		rules.text = desk_text.to_core()
	rules.recap_agree_format = recap_agree_format
	rules.recap_legal_format = recap_legal_format
	rules.recap_mercy_format = recap_mercy_format
	rules.recap_neither_format = recap_neither_format
	rules.recap_uncertain_format = recap_uncertain_format
	rules.recap_never_line = recap_never_line
	rules.ledger_open_format = ledger_open_format
	rules.ledger_kept_format = ledger_kept_format
	rules.ledger_broken_format = ledger_broken_format
	rules.ledger_lapsed_format = ledger_lapsed_format
	rules.mentor_mercy_warning_format = mentor_mercy_warning_format
	rules.mentor_illegal_warning_format = mentor_illegal_warning_format
	rules.mentor_mercy_format = mentor_mercy_format
	rules.mentor_liar_format = mentor_liar_format
	rules.mentor_honest_format = mentor_honest_format
	rules.mentor_promise_format = mentor_promise_format
	rules.mentor_grey_line = mentor_grey_line
	rules.mentor_grey_huginn_line = mentor_grey_huginn_line
	rules.mentor_tide_line = mentor_tide_line
	rules.mentor_tide_suffix = mentor_tide_suffix
	rules.liar_decree_id = liar_decree_id
	rules.liar_realm = liar_realm
	rules.huginn_claim_answer = huginn_claim_answer
	rules.huginn_witness_answer = huginn_witness_answer
	rules.citation_format = citation_format
	rules.threaded_line = threaded_line
	rules.returned_format = returned_format
	rules.hel_offer_format = hel_offer_format
	return rules


## Starts a run on `desk` from this data (phase: day-1 dawn).
func start(desk: DeskCommands) -> void:
	var day_rules: Array[DayRules] = []
	var queues: Array = []
	for day: DayData in days:
		day_rules.append(day.to_core())
		queues.append(day.encounters_to_core())
	var variants: Dictionary = {}
	if returned_ignored != null:
		variants[&"ignored"] = returned_ignored.to_core()
	if returned_missed != null:
		variants[&"missed"] = returned_missed.to_core()
	if fallback != null:
		variants[&"fallback"] = fallback.to_core()
	desk.start_run(day_rules, queues, rules_to_core(), variants)
