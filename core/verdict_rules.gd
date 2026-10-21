class_name VerdictRules
extends RefCounted
## Judges a stamp: correct, citation (or a day-1 warning), ignored or missed, and permitted
## uncertainty (GDD §3.7, D8, D28, D37, D38). Feathers are the caller's (Economy).


## The realm a seam shows, or &"". A lie seam shows the liar's realm only when the claim is the
## liar; a grey seam shows it only once Huginn has named the liar on that thread (D37).
static func shown_realm(seam: Seam, record: VerdictRecord, rules: SliceRules) -> StringName:
	match seam.kind:
		Seam.Kind.LAW:
			return seam.destination
		Seam.Kind.RED:
			return rules.liar_realm if seam.liar == Seam.Liar.CLAIM else &""
		Seam.Kind.GREY:
			if seam.liar == Seam.Liar.CLAIM and record.answer_for(seam) != "":
				return rules.liar_realm
	return &""


## The visible seam that shows the legal realm, preferring one the player threaded; null if none.
static func decisive_seam(record: VerdictRecord, day: DayRules, rules: SliceRules) -> Seam:
	var encounter: Encounter = record.encounter
	var first: Seam = null
	for seam: Seam in encounter.seams:
		if not _on_desk(seam, encounter, day):
			continue
		if shown_realm(seam, record, rules) != encounter.legal_realm:
			continue
		if record.is_threaded(seam):
			return seam
		if first == null:
			first = seam
	return first


static func judge(
	record: VerdictRecord, realm: StringName, day: DayRules, rules: SliceRules
) -> StampResult:
	var result := StampResult.new()
	result.valid = true
	result.realm = realm
	result.correct = realm == record.encounter.legal_realm
	if result.correct:
		return result
	var seam: Seam = decisive_seam(record, day, rules)
	if seam == null:
		result.uncertain = _has_unanswered_grey(record)
		return result
	result.citation = day.citations
	result.warning = not day.citations
	result.ignored = record.is_threaded(seam)
	result.citation_a = seam.a
	result.citation_b = seam.b
	result.citation_text = citation_text(seam, record.encounter, day, rules, result.ignored)
	return result


## The ending's mark, against the worthy destination (D2, D23): the decisive seam threaded is
## ignored, unthreaded is missed; a stamp that only an unanswered grey thread showed is uncertain.
static func mark_for(record: VerdictRecord, day: DayRules, rules: SliceRules) -> StringName:
	if not record.judged():
		return VerdictRecord.NEVER
	if record.verdict == record.encounter.worthy_realm:
		return &""
	if record.result != null and record.result.uncertain:
		return VerdictRecord.UNCERTAIN
	var seam: Seam = decisive_seam(record, day, rules)
	if seam != null and record.is_threaded(seam):
		return VerdictRecord.IGNORED
	return VerdictRecord.MISSED


static func citation_text(
	seam: Seam, encounter: Encounter, day: DayRules, rules: SliceRules, ignored: bool
) -> String:
	var decree_id: String = rules.liar_decree_id
	if seam.kind == Seam.Kind.LAW:
		decree_id = seam.b if day.decree(seam.b) != null else seam.a
	var text: String = (
		rules.citation_format
		% [decree_id, _shown(seam.a, encounter, day), _shown(seam.b, encounter, day)]
	)
	if ignored:
		text += " " + rules.threaded_line
	return text


## The mentor's comment on an unguided soul's illegal stamp (D16), naming the visible pair. Mercy
## is the worthy realm chosen against the legal one; anything else is an illegal stamp. Call after
## the stamp is settled (it reads the citation's cost). "" when the stamp was legal, the soul is
## guided, or no seam showed the Law (permitted uncertainty, D37).
static func mentor_line(
	record: VerdictRecord, result: StampResult, day: DayRules, rules: SliceRules
) -> String:
	var encounter: Encounter = record.encounter
	if result.correct or not encounter.mentor_steps.is_empty() or result.citation_a == "":
		return ""
	var line_format: String = rules.mentor_illegal_format
	if result.realm == encounter.worthy_realm:
		line_format = rules.mentor_mercy_format
	var line: String = (
		line_format
		% [_shown(result.citation_a, encounter, day), _shown(result.citation_b, encounter, day)]
	)
	if result.warning:
		line += " " + rules.mentor_warning_line
	elif result.citation:
		line += " " + rules.mentor_cost_format % result.citation_loss
	return line


static func _shown(item_id: String, encounter: Encounter, day: DayRules) -> String:
	var item: EvidenceItem = encounter.item(item_id)
	if item == null:
		return item_id if day.decree(item_id) != null else ""
	if item.group == EvidenceItem.Group.BODY:
		return item.text
	return '"%s"' % item.text.trim_suffix(".")


static func _on_desk(seam: Seam, encounter: Encounter, day: DayRules) -> bool:
	return (
		PinResolver.is_visible(encounter, day.decrees, seam.a)
		and PinResolver.is_visible(encounter, day.decrees, seam.b)
	)


static func _has_unanswered_grey(record: VerdictRecord) -> bool:
	for seam: Seam in record.encounter.seams:
		if seam.kind == Seam.Kind.GREY and record.answer_for(seam) == "":
			return true
	return false
