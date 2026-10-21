class_name RunState
extends RefCounted
## The run's state: the day, the queue, feathers and rank, every verdict record, Hel's promise and
## the return arc. DeskCommands drives it; this class holds the day-level bookkeeping.

const DAWN := &"dawn"
const DESK := &"desk"
const DUSK := &"dusk"
const ENDING := &"ending"

const PROMISE_NONE := &"none"
const PROMISE_OPEN := &"open"
const PROMISE_KEPT := &"kept"
const PROMISE_BROKEN := &"broken"
const PROMISE_LAPSED := &"lapsed"

var days: Array[DayRules] = []
## One Array[Encounter] per day; a day's return slot is inserted, not listed here.
var encounters_by_day: Array = []
var rules: SliceRules = SliceRules.new()
## {&"ignored": Encounter, &"missed": Encounter, &"fallback": Encounter}; may be empty.
var returned_variants: Dictionary = {}

var day_index: int = 0
var phase: StringName = DAWN
var queue: Array[Encounter] = []
var slot: int = 0
## Every encounter seated so far, in order, judged or not.
var records: Array[VerdictRecord] = []
## The soul at the desk; null outside the desk phase.
var current: VerdictRecord = null
## A stamped soul still on the desk with its citation, until next_soul() (D48); null otherwise.
var awaiting: VerdictRecord = null
var economy: Economy = Economy.new(rules)
var clock: DayClock = DayClock.new()
var paused: bool = false
var huginn_left: int = 0
var stamps_today: int = 0
var citations_today: Array[String] = []
var promise: StringName = PROMISE_NONE
var promise_soul: String = ""
var promise_changed_today: bool = false
## Decided at the dusk before the day with a return slot (D2).
var returning: Encounter = null
var dusk: DuskReport = null


func reset(
	p_days: Array[DayRules], p_encounters: Array, p_rules: SliceRules, p_variants: Dictionary
) -> void:
	days = p_days
	encounters_by_day = p_encounters
	rules = p_rules
	returned_variants = p_variants
	day_index = 0
	records = []
	economy = Economy.new(rules)
	promise = PROMISE_NONE
	promise_soul = ""
	returning = null
	dusk = null
	paused = false
	open_day()


func day_rules() -> DayRules:
	return days[day_index] if day_index < days.size() else DayRules.new()


func has_next_day() -> bool:
	return day_index + 1 < days.size()


## Dawn of the current day: a fresh queue, clock and Huginn budget.
func open_day() -> void:
	var day: DayRules = day_rules()
	phase = DAWN
	queue = []
	if day_index < encounters_by_day.size():
		for encounter: Encounter in encounters_by_day[day_index]:
			queue.append(encounter)
	if day.return_slot >= 0 and returning != null:
		queue.insert(mini(day.return_slot, queue.size()), returning)
	slot = 0
	current = null
	awaiting = null
	clock = DayClock.new(day.clock_seconds, rules.clock_warning_seconds)
	clock.paused = paused
	huginn_left = day.huginn_answers
	stamps_today = 0
	citations_today = []
	promise_changed_today = false
	economy.start_day()


## Seats queue[slot] at the desk, or ends the day when the queue is done.
func seat_next() -> void:
	if slot >= queue.size():
		end_day()
		return
	current = VerdictRecord.make(queue[slot], day_rules().day)
	records.append(current)


func end_day() -> void:
	var day: DayRules = day_rules()
	for index: int in range(slot, queue.size()):
		var record: VerdictRecord = current if index == slot and current != null else null
		if record == null:
			record = VerdictRecord.make(queue[index], day.day)
			records.append(record)
		record.mark = VerdictRecord.NEVER
		if queue[index].hel_marked and promise == PROMISE_OPEN:
			promise = PROMISE_LAPSED
			promise_changed_today = true
	slot = queue.size()
	current = null
	awaiting = null
	var report := DuskReport.new()
	report.day = day.day
	report.citations = citations_today.duplicate()
	report.quota = day.quota
	report.admitted = admitted_today()
	var demotions: int = economy.demotions
	if report.admitted >= day.quota:
		report.quota_delta = rules.quota_met_reward
		economy.gain(rules.quota_met_reward)
	else:
		report.quota_delta = -economy.lose((day.quota - report.admitted) * rules.quota_short_cost)
	report.demoted = economy.demotions > demotions
	report.recap = _recap(day.day)
	report.never_judged = _never_judged(day.day)
	report.story = day.dusk_story
	if promise_changed_today:
		report.requests.append(rules.promise_format % [promise_soul, promise])
	if has_next_day():
		_prepare_tomorrow(report)
	report.feathers = economy.feathers
	report.rank = economy.rank
	report.rank_name = economy.rank_name()
	dusk = report
	phase = DUSK if has_next_day() else ENDING


func hel_tide() -> int:
	var count: int = 0
	for record: VerdictRecord in records:
		if record.verdict == Realm.HEL and record.encounter.worthy_realm != Realm.HEL:
			count += 1
	return count


func admitted_today() -> int:
	var count: int = 0
	for record: VerdictRecord in records:
		if record.day == day_rules().day and record.verdict == Realm.VALHALLA:
			count += 1
	return count


## Hel's offer and the return arc are settled at this dusk, so skipping dusk loses nothing (D3).
func _prepare_tomorrow(report: DuskReport) -> void:
	var tomorrow: int = day_index + 1
	if promise == PROMISE_NONE and tomorrow < encounters_by_day.size():
		for encounter: Encounter in encounters_by_day[tomorrow]:
			if encounter.hel_marked:
				promise = PROMISE_OPEN
				promise_soul = encounter.soul_name
				report.requests.append(rules.hel_offer_format % [promise_soul, rules.hel_reward])
				break
	if days[tomorrow].return_slot < 0:
		return
	returning = returned_variants.get(&"fallback", null)
	for record: VerdictRecord in records:
		if not record.encounter.return_eligible or record.verdict != Realm.HEL:
			continue
		var key: StringName = &"ignored" if record.mark == VerdictRecord.IGNORED else &"missed"
		var variant: Encounter = returned_variants.get(key, null)
		if variant != null:
			returning = variant
			report.returned_line = rules.returned_format % variant.soul_name


func _recap(day: int) -> Array[String]:
	var wrong: Array[VerdictRecord] = []
	var rest: Array[VerdictRecord] = []
	for record: VerdictRecord in records:
		if record.day != day:
			continue
		if record.judged() and record.verdict != record.encounter.worthy_realm:
			wrong.append(record)
		else:
			rest.append(record)
	var lines: Array[String] = []
	for record: VerdictRecord in wrong + rest:
		if lines.size() >= 3:
			break
		var line: String = "%s: %s" % [record.encounter.soul_name, record.encounter.truth]
		if record.result != null and record.result.uncertain:
			line += " " + rules.uncertain_line
		lines.append(line)
	return lines


func _never_judged(day: int) -> Array[String]:
	var names: Array[String] = []
	for record: VerdictRecord in records:
		if record.day == day and not record.judged():
			names.append(record.encounter.soul_name)
	return names


## Books a judged stamp: the citation's capped loss, then Hel's reward (D29, D36), the verdict
## and its mark. The soul leaves the queue; the caller seats the next one (or holds it, D48).
func settle_stamp(record: VerdictRecord, result: StampResult) -> void:
	var feathers_before: int = economy.feathers
	var demotions_before: int = economy.demotions
	if result.citation:
		result.citation_loss = economy.lose(rules.citation_cost)
		citations_today.append(result.citation_text)
	if record.encounter.hel_marked and promise == PROMISE_OPEN:
		promise_changed_today = true
		if result.realm == Realm.HEL:
			promise = PROMISE_KEPT
			result.reward = rules.hel_reward
			economy.gain(result.reward)
		else:
			promise = PROMISE_BROKEN
	result.feathers_delta = economy.feathers - feathers_before
	result.demoted = economy.demotions > demotions_before
	record.verdict = result.realm
	record.result = result
	record.mark = VerdictRules.mark_for(record, day_rules(), rules)
	stamps_today += 1
	slot += 1
	current = null
