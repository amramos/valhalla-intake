# gdlint: disable=max-public-methods
class_name DeskCommands
extends RefCounted
## The one command layer (D13): the desk UI and the text harness call only this, and read only
## its getters and signals. It owns the RunState. It is the whole command surface, hence the
## public-method lint is off for this file.

signal desk_changed
signal clock_warning
signal horn
signal citation_given(text: String, a: String, b: String)
signal stamped(result: StampResult)

var _state: RunState = RunState.new()
## Simulated time charged at each stamp (the harness); the real desk lets real time pass instead.
var _stamp_seconds: float = 0.0


func start_run(
	days: Array[DayRules],
	encounters_by_day: Array,
	rules: SliceRules,
	returned_variants: Dictionary
) -> void:
	_state.reset(days, encounters_by_day, rules, returned_variants)
	desk_changed.emit()


## The whole day-1 dawn state (D31).
func restart_run() -> void:
	start_run(_state.days, _state.encounters_by_day, _state.rules, _state.returned_variants)


## &"dawn", &"desk", &"dusk" or &"ending" (RunState constants).
func phase() -> StringName:
	return _state.phase


func begin_day() -> void:
	if _state.phase != RunState.DAWN:
		return
	_state.phase = RunState.DESK
	_state.seat_next()
	desk_changed.emit()


func next_day() -> void:
	if _state.phase != RunState.DUSK or not _state.has_next_day():
		return
	_state.day_index += 1
	_state.open_day()
	desk_changed.emit()


## The current day's rules; read-only by convention.
func day_rules() -> DayRules:
	return _state.day_rules()


## The slice's tunables and desk text; read-only by convention.
func slice_rules() -> SliceRules:
	return _state.rules


func day_number() -> int:
	return _state.day_rules().day


## The soul on the desk: the one being judged, or the cited one awaiting next_soul() (D48).
func current_encounter() -> Encounter:
	var record: VerdictRecord = _shown()
	return record.encounter if record != null else null


## (1-based position of the soul on the desk, souls in today's queue).
func queue_position() -> Vector2i:
	var shown: int = _state.slot if _state.awaiting != null else _state.slot + 1
	return Vector2i(shown, _state.queue.size())


func visible_items() -> Array[EvidenceItem]:
	var items: Array[EvidenceItem] = []
	if _shown() == null:
		return items
	items.append_array(_shown().encounter.items)
	items.append_array(_state.day_rules().decrees)
	return items


func threads() -> Array[Seam]:
	var seams: Array[Seam] = []
	if _shown() != null:
		seams.append_array(_shown().threads)
	return seams


## Huginn's answer on a thread, "" until asked.
func thread_answer(thread_index: int) -> String:
	var record: VerdictRecord = _shown()
	if record == null or thread_index < 0 or thread_index >= record.answers.size():
		return ""
	return record.answers[thread_index]


## True while a cited (or, on day 1, warned) soul stays on the desk with its black feather and
## lit pair (D48). Nothing can be pinned or stamped and the clock stands until next_soul().
func awaiting_next() -> bool:
	return _state.awaiting != null


## The stamp that holds the desk (its citation text and pair); null when not awaiting.
func pending_stamp() -> StampResult:
	return _state.awaiting.result if _state.awaiting != null else null


## Calls the next soul after a citation ("Next soul"); ends the day after the last one.
func next_soul() -> void:
	if _state.awaiting == null:
		return
	_state.awaiting = null
	if _check_clock():
		return
	_state.seat_next()
	desk_changed.emit()


func pin(a: String, b: String) -> PinResult:
	if _state.current == null:
		return PinResult.new()
	var record: VerdictRecord = _state.current
	var result: PinResult = PinResolver.resolve(
		record.encounter, _state.day_rules().decrees, a, b, record.threads
	)
	if result.kind == PinResult.Kind.INVALID:
		return result
	record.pins.append("%s|%s" % [a, b])
	if result.kind == PinResult.Kind.THREAD:
		record.threads.append(result.seam)
		record.answers.append("")
		if result.seam.kind == Seam.Kind.GREY and not _state.grey_commented_today:
			_state.grey_commented_today = true
			result.mentor_line = _state.rules.mentor_grey_line
			if _state.day_rules().huginn_answers > 0:
				result.mentor_line = _state.rules.mentor_grey_huginn_line
	if record.pins.size() == 1:
		MentorGuide.finish_reading(record)
	if result.seam != null:
		MentorGuide.finish(record, MentorStep.Until.PIN, result.seam)
	elif result.kind == PinResult.Kind.NO_SEAM and _state.clock.is_timed():
		result.seconds_lost = _state.rules.no_seam_seconds
		_state.clock.charge(result.seconds_lost)
	_after_action()
	return result


## Spends one answer on a grey thread; "" when not allowed. A thread already answered repeats its
## answer for free (the answer stays on its thread).
func ask_huginn(thread_index: int) -> String:
	if _state.current == null or _state.day_rules().huginn_answers <= 0:
		return ""
	var record: VerdictRecord = _state.current
	if thread_index < 0 or thread_index >= record.threads.size():
		return ""
	var seam: Seam = record.threads[thread_index]
	if seam.kind != Seam.Kind.GREY:
		return ""
	if record.answers[thread_index] != "":
		return record.answers[thread_index]
	if _state.huginn_left <= 0:
		return ""
	_state.huginn_left -= 1
	var answer: String = _state.rules.huginn_claim_answer
	if seam.liar == Seam.Liar.WITNESS:
		answer = _state.rules.huginn_witness_answer
	record.answers[thread_index] = answer
	_state.clock.charge(_state.rules.huginn_seconds)
	_after_action()
	return answer


## Buys one more answer for feathers once today's are spent (D30); a spend, never a loss.
func buy_huginn_answer() -> bool:
	if _state.current == null or _state.day_rules().huginn_answers <= 0:
		return false
	if _state.huginn_left > 0 or not _state.economy.can_spend(_state.rules.huginn_extra_cost):
		return false
	_state.spend_on_huginn()
	_state.huginn_left += 1
	desk_changed.emit()
	return true


func stamp(realm: StringName) -> StampResult:
	var day: DayRules = _state.day_rules()
	if _state.current == null or not day.doors_open.has(realm):
		var refused := StampResult.new()
		refused.realm = realm
		return refused
	var record: VerdictRecord = _state.current
	var result: StampResult = VerdictRules.judge(record, realm, day, _state.rules)
	MentorGuide.finish(record, MentorStep.Until.STAMP)
	var tide_before: int = _state.hel_tide()
	_state.settle_stamp(record, result)
	result.mentor_line = VerdictRules.mentor_line(record, result, day, _state.rules)
	if tide_before == 0 and _state.hel_tide() == 1:
		# Hel's tide is explained the first time it grows (D53).
		if result.mentor_line == "":
			result.mentor_line = _state.rules.mentor_tide_line
		else:
			result.mentor_line += " " + _state.rules.mentor_tide_suffix
	# The stamp has completed (D36); its time applies on every slot alike.
	_state.clock.charge(_stamp_seconds)
	# A citation holds the desk even when the stamp ran the clock out: the horn waits for
	# next_soul(), so the cited pair never vanishes unseen (D36, D48).
	if result.citation or result.warning:
		_state.awaiting = record
	elif not _state.clock.is_out():
		_state.seat_next()
	if result.citation:
		citation_given.emit(result.citation_text, result.citation_a, result.citation_b)
	stamped.emit(result)
	if not _check_clock():
		desk_changed.emit()
	return result


## Simulated seconds charged at each stamp; the harness sets it, the real desk leaves it at 0.
func set_stamp_seconds(seconds: float) -> void:
	_stamp_seconds = maxf(seconds, 0.0)


## Real time on the desk (the UI per frame, the harness per action). Poll time_left() to redraw.
func advance_time(seconds: float) -> void:
	if _state.phase != RunState.DESK or _state.awaiting != null:
		return
	_state.clock.tick(seconds)
	_check_clock()


func set_paused(paused: bool) -> void:
	_state.paused = paused
	_state.clock.paused = paused


func is_paused() -> bool:
	return _state.paused


## INF when untimed.
func time_left() -> float:
	return _state.clock.time_left()


func feathers() -> int:
	return _state.economy.feathers


func rank() -> int:
	return _state.economy.rank


func rank_name() -> String:
	return _state.economy.rank_name()


## (souls admitted to Valhalla today, today's quota).
func quota_progress() -> Vector2i:
	return Vector2i(_state.admitted_today(), _state.day_rules().quota)


func huginn_left() -> int:
	return _state.huginn_left


## The figures at Hel's door: souls stamped to Hel this run that were not worthy of Hel (D21, D23).
func hel_tide() -> int:
	return _state.hel_tide()


## The mentor's current guided step on the soul being judged; null when there is none (D16).
func mentor_step() -> MentorStep:
	return MentorGuide.current(_state.current)


## Finishes a READ step (the bubble's "Next"); PIN and STAMP steps finish by the player's action.
func mentor_ack() -> void:
	if MentorGuide.finish(_state.current, MentorStep.Until.READ):
		desk_changed.emit()


## &"none", &"open", &"kept", &"broken" or &"lapsed" (RunState); the ledger badge shows "open".
func promise_state() -> StringName:
	return _state.promise


## The soul Hel named ("" before her offer) and what she pays if it is sent to her.
func promise_soul() -> String:
	return _state.promise_soul


func promise_reward() -> int:
	return _state.rules.hel_reward


## The ledger's entry for Hel's promise in its current state (matrix A6); "" before her offer.
func ledger_line() -> String:
	return _state.ledger_line()


## NEW marks on today's new decrees and doors show until the day's first stamp (D34).
func shows_new_marks() -> bool:
	return _state.stamps_today == 0


## The first day a door is open, or 0 if it never opens in this run ("Closed until day N").
func door_open_day(realm: StringName) -> int:
	for day: DayRules in _state.days:
		if day.doors_open.has(realm):
			return day.day
	return 0


## The last dusk's report (the day just ended); an empty report before the first dusk.
func dusk_report() -> DuskReport:
	return _state.dusk if _state.dusk != null else DuskReport.new()


func ending() -> EndingReport:
	var report: EndingReport = EndingCalculator.calculate(_state.records, _state.rules)
	report.feathers = _state.economy.feathers
	report.rank = _state.economy.rank
	report.rank_name = _state.economy.rank_name()
	report.promise_soul = _state.promise_soul
	report.promise_state = _state.promise
	report.promise_line = _state.ledger_line()
	if _state.phase == RunState.ENDING:
		report.last_dusk = _state.dusk
	return report


## Debug only (screenshots, the harness): restarts the run and stamps every earlier soul to its
## legal realm (or, if merciful, its worthy one) until soul `slot` of day `day` (both 1-based)
## is at the desk.
func debug_jump(day: int, slot: int, merciful: bool = false) -> void:
	var stamp_seconds: float = _stamp_seconds
	_stamp_seconds = 0.0
	restart_run()
	for _step: int in range(1000):
		if _state.phase == RunState.DAWN:
			begin_day()
		elif _state.phase == RunState.DUSK and day_number() < day:
			next_day()
		elif _state.phase == RunState.DESK and _state.awaiting != null:
			next_soul()
		elif _state.phase == RunState.DESK and (day_number() < day or _state.slot + 1 < slot):
			var encounter: Encounter = current_encounter()
			stamp(encounter.worthy_realm if merciful else encounter.legal_realm)
		else:
			break
	_stamp_seconds = stamp_seconds


func _after_action() -> void:
	# An action in progress completes before the horn (D36).
	_check_clock()
	if _state.phase == RunState.DESK:
		desk_changed.emit()


## Emits the warning and, when the clock is out, ends the day with the horn; true on the horn.
func _check_clock() -> bool:
	if _state.clock.take_warning():
		clock_warning.emit()
	if _state.phase != RunState.DESK or _state.awaiting != null or not _state.clock.is_out():
		return false
	_state.end_day()
	horn.emit()
	desk_changed.emit()
	return true


func _shown() -> VerdictRecord:
	return _state.current if _state.current != null else _state.awaiting
