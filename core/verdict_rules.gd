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
	# The citation names the decree as the scroll does, by its numeral (D6).
	var decree: String = DecreeNumeral.label(decree_of(seam, day, rules))
	var text: String = rules.citation_format % [decree, pair_text(seam, encounter, day)]
	if ignored:
		text += " " + rules.threaded_line
	return text


## The decree a seam cites, by id: a law thread's own decree, or the liars' decree for a lie seam.
static func decree_of(seam: Seam, day: DayRules, rules: SliceRules) -> String:
	if seam.kind != Seam.Kind.LAW:
		return rules.liar_decree_id
	return seam.b if day.decree(seam.b) != null else seam.a


## The pair as a citation names it (A3): the authored text, or one built from the two items in the
## same voice: "Wet to the knee, and 'Dry when I fell'", "'Left the fight' and decree IV".
static func pair_text(seam: Seam, encounter: Encounter, day: DayRules) -> String:
	if seam.pair_text != "":
		return seam.pair_text
	var first: String = _shown(seam.a, encounter, day)
	var second: String = _shown(seam.b, encounter, day)
	var a_item: EvidenceItem = encounter.item(seam.a)
	var joiner: String = (
		", and " if a_item != null and a_item.group == EvidenceItem.Group.BODY else " and "
	)
	return first.left(1).to_upper() + first.substr(1) + joiner + second


## The mentor's comment on a wrong stamp (matrix A2), naming the cited pair. Mercy is the worthy
## realm chosen against the Law; anything else is illegal, and from day 2 it says whether the soul
## lied. Keeping Hel's promise has its own line. "" for a legal stamp, or when no seam showed the
## Law (permitted uncertainty, D37). Call after the stamp is settled (it reads Hel's reward).
static func mentor_line(
	record: VerdictRecord, result: StampResult, day: DayRules, rules: SliceRules
) -> String:
	var encounter: Encounter = record.encounter
	if result.correct or result.citation_a == "":
		return ""
	var seam: Seam = encounter.seam_between(result.citation_a, result.citation_b)
	var pair: String = pair_text(seam, encounter, day)
	if result.reward > 0:
		return rules.mentor_promise_format % pair
	var mercy: bool = result.realm == encounter.worthy_realm
	if result.warning:
		var warning: String = (
			rules.mentor_mercy_warning_format if mercy else rules.mentor_illegal_warning_format
		)
		return warning % pair
	if mercy:
		return rules.mentor_mercy_format % pair
	return (rules.mentor_liar_format if encounter.liar else rules.mentor_honest_format) % pair


static func _shown(item_id: String, encounter: Encounter, day: DayRules) -> String:
	var item: EvidenceItem = encounter.item(item_id)
	if item == null:
		return DecreeNumeral.label(item_id) if day.decree(item_id) != null else ""
	if item.group == EvidenceItem.Group.BODY:
		return item.text
	return "'%s'" % item.text.trim_suffix(".")


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
