class_name PinResolver
extends RefCounted
## Resolves a pin of two visible items against the encounter's seams (D8, D24, D38).


## The pin's kind and seam; the caller charges the clock for NO_SEAM.
static func resolve(
	encounter: Encounter, decrees: Array[EvidenceItem], a: String, b: String, threaded: Array[Seam]
) -> PinResult:
	var result := PinResult.new()
	if a == b or not is_visible(encounter, decrees, a) or not is_visible(encounter, decrees, b):
		result.kind = PinResult.Kind.INVALID
		return result
	var seam: Seam = encounter.seam_between(a, b)
	if seam == null:
		# Red herrings included: anything not authored as a seam is no seam (D24).
		result.kind = PinResult.Kind.NO_SEAM
		return result
	result.seam = seam
	result.kind = PinResult.Kind.ALREADY if threaded.has(seam) else PinResult.Kind.THREAD
	return result


static func is_visible(encounter: Encounter, decrees: Array[EvidenceItem], item_id: String) -> bool:
	if encounter.item(item_id) != null:
		return true
	for decree: EvidenceItem in decrees:
		if decree.id == item_id:
			return true
	return false
