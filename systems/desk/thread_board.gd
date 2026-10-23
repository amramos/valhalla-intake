class_name ThreadBoard
extends RefCounted
## Draws the soul's threads on the desk's thread layer (D8): one ThreadLine per thread, routed by
## ThreadRouter between the panels that hold its two items, in pin order, alternating lanes.

const GREY_KNOT_HOVER := "grey thread: one of them lies"

var router := ThreadRouter.new()
## The clerk's note, a paper a slack thread may never fall onto; optional (set by the desk).
var note: Control = null

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
		var a: EvidenceItem = find_item(items, threads[index].a)
		var b: EvidenceItem = find_item(items, threads[index].b)
		if a == null or b == null:
			continue
		var answer: String = answers[index] if index < answers.size() else ""
		var line := ThreadLine.new()
		line.name = "Thread%d" % index
		line.lane = index % 2
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


## A pin with no seam (D36): a thread routed between `a` and `b` on the thread layer, with no knot
## or bead, for the desk to slacken and drop at once. It is no thread of the soul's: the next
## rebuild frees it with the rest. Null when either item is missing.
func make_slack(a: EvidenceItem, b: EvidenceItem) -> ThreadLine:
	if a == null or b == null:
		return null
	var line := ThreadLine.new()
	line.name = "Slack"
	_layer.add_child(line)
	line.size = _layer.size
	var ends: Array = _ends(a, b)
	line.points = router.route(ends[0], ends[1], ends[2], ends[3], ends[4], ends[5], 0)
	line.caps = router.caps(ends[0], ends[1], ends[2], ends[3], ends[4], ends[5])
	line.drop_limit = clear_drop(line.stroke(), papers(), ThreadLine.DROP_PIXELS)
	line.queue_redraw()
	return line


## The papers on the desk, in global pixels: the slab, the shown sheets, the Law and the note.
func papers() -> Array[Rect2]:
	var rects: Array[Rect2] = [_chart.get_global_rect()]
	for paper: Control in [_claim, _witness, _law, note]:
		if paper != null and paper.is_visible_in_tree():
			rects.append(paper.get_global_rect())
	return rects


## How far (0 to `most` pixels) the strand of pixels `stroke` can fall straight down before any of
## its pixels would lie on one of `sheets`; 0 when the strand already lies on one.
static func clear_drop(stroke: Array[Vector2i], sheets: Array[Rect2], most: int) -> int:
	for drop: int in range(most + 1):
		for pixel: Vector2i in stroke:
			var below := Vector2(pixel.x, pixel.y + drop)
			for sheet: Rect2 in sheets:
				if sheet.has_point(below):
					return maxi(drop - 1, 0)
	return most


## The visible item with `item_id` among `items`; null when none.
static func find_item(items: Array[EvidenceItem], item_id: String) -> EvidenceItem:
	for item: EvidenceItem in items:
		if item.id == item_id:
			return item
	return null


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
