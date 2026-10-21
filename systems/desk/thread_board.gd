class_name ThreadBoard
extends RefCounted
## Draws the soul's threads on the desk's thread layer (D8): one ThreadLine per thread, routed by
## ThreadRouter between the panels that hold its two items, in pin order, alternating lanes.

const GREY_KNOT_HOVER := "grey thread: one of them lies"

var router := ThreadRouter.new()

var _chart: BodyChart
var _claim: EvidencePanel
var _witness: EvidencePanel
var _law: EvidencePanel
var _layer: Control


func _init(
	chart: BodyChart,
	claim: EvidencePanel,
	witness: EvidencePanel,
	law: EvidencePanel,
	layer: Control
) -> void:
	_chart = chart
	_claim = claim
	_witness = witness
	_law = law
	_layer = layer


## Replaces the drawn threads. `answers[i]` is Huginn's answer on thread i ("" until asked); it
## fills the knot and becomes its hover text. `selected` is the thread whose knot is selected
## (-1 for none). Returns the new lines.
func rebuild(
	threads: Array[Seam], items: Array[EvidenceItem], answers: Array[String], selected: int
) -> Array[ThreadLine]:
	for child: Node in _layer.get_children():
		child.queue_free()
	var lines: Array[ThreadLine] = []
	var avoid: Array[Rect2] = _chart.hit_rects()
	for panel: EvidencePanel in [_claim, _witness, _law]:
		avoid.append_array(panel.hit_rects())
	for index: int in range(threads.size()):
		var a: EvidenceItem = _find(items, threads[index].a)
		var b: EvidenceItem = _find(items, threads[index].b)
		if a == null or b == null:
			continue
		var answer: String = answers[index] if index < answers.size() else ""
		var line := ThreadLine.new()
		line.name = "Thread%d" % index
		_layer.add_child(line)
		line.size = _layer.size
		var ends: Array = _ends(a, b)
		line.setup(
			threads[index].kind,
			index,
			router.route(ends[0], ends[1], ends[2], ends[3], ends[4], ends[5], index % 2),
			router.caps(ends[0], ends[1], ends[2], ends[3], ends[4], ends[5]),
			_hover_for(threads[index], answer),
			avoid
		)
		line.answered = answer != ""
		line.selected = index == selected
		lines.append(line)
	return lines


## A grey knot hovers Huginn's answer once given; every other bead hovers its caption.
func _hover_for(seam: Seam, answer: String) -> String:
	if seam.kind != Seam.Kind.GREY:
		return seam.caption
	return "Huginn: " + answer if answer != "" else GREY_KNOT_HOVER


## [column_a, item_a, panel_a, column_b, item_b, panel_b] for the router.
func _ends(a: EvidenceItem, b: EvidenceItem) -> Array:
	return [
		ThreadRouter.column_of(a.group),
		_anchor(a),
		_holder(a).get_global_rect(),
		ThreadRouter.column_of(b.group),
		_anchor(b),
		_holder(b).get_global_rect(),
	]


func _find(items: Array[EvidenceItem], item_id: String) -> EvidenceItem:
	for item: EvidenceItem in items:
		if item.id == item_id:
			return item
	return null


func _anchor(item: EvidenceItem) -> Rect2:
	if item.group == EvidenceItem.Group.BODY:
		return _chart.anchor_rect(item.id)
	return (_holder(item) as EvidencePanel).anchor_rect(item.id)


func _holder(item: EvidenceItem) -> Control:
	match item.group:
		EvidenceItem.Group.BODY:
			return _chart
		EvidenceItem.Group.CLAIM:
			return _claim
		EvidenceItem.Group.WITNESS:
			return _witness
	return _law
