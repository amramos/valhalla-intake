class_name ThreadRouter
extends RefCounted
## Routes a thread between two pinned items along the gutters between panels, so a thread never
## crosses text (D8, D21). Pure geometry: rectangles in, an axis-aligned polyline out.
##
## The desk's columns, left to right: the body chart, the claim and witness column, the Law. Each
## gap between them is a gutter two lanes wide; a third gutter runs along the top of the desk band.
## A thread from a fact leaves sideways to the chart's margin (see _from_fact).

## Where an endpoint sits.
enum Column { BODY, TESTIMONY, LAW }

## The left lane of the gutter between the body chart and the testimony column.
var body_gutter_x: int = 131
## The left lane of the gutter between the testimony column and the Law.
var law_gutter_x: int = 271
## The upper lane of the gutter along the top of the desk band.
var top_gutter_y: int = 97
## Pixels between the two lanes of a gutter.
var lane_step: int = 2


## The route between two endpoints. `item_*` is the pinned item's rectangle and `panel_*` the
## rectangle of the panel holding it (the body chart for a fact). `lane` is 0 or 1.
func route(
	column_a: Column,
	item_a: Rect2,
	panel_a: Rect2,
	column_b: Column,
	item_b: Rect2,
	panel_b: Rect2,
	lane: int = 0
) -> PackedVector2Array:
	if column_a > column_b:
		return _reversed(route(column_b, item_b, panel_b, column_a, item_a, panel_a, lane))
	var offset: int = (lane % 2) * lane_step
	var g1: float = body_gutter_x + offset
	var g2: float = law_gutter_x + offset
	var top: float = top_gutter_y + offset
	var ya: float = _mid_y(item_a)
	var yb: float = _mid_y(item_b)
	if column_a == Column.BODY and column_b == Column.BODY:
		return PackedVector2Array([item_a.get_center().floor(), item_b.get_center().floor()])
	var gutter: float = g2 if column_b == Column.LAW else g1
	var points: Array[Vector2] = []
	if column_a == Column.BODY:
		points = _from_fact(item_a, panel_a, ya, g1, gutter, top)
	else:
		var exits_right: bool = column_a == Column.TESTIMONY and column_b == Column.LAW
		var exit_x: float = panel_a.end.x if exits_right else panel_a.position.x - 1
		points = [Vector2(exit_x, ya), Vector2(gutter, ya)]
	points.append(Vector2(gutter, yb))
	points.append(Vector2(panel_b.position.x - 1, yb))
	return PackedVector2Array(points)


## A thread leaves a fact sideways, never across the other view or a head: a front-view fact
## (left half of the chart) runs out to the chart's left margin and up to the top gutter; a
## back-view fact runs right into the body gutter. Both then reach `gutter` along the top.
func _from_fact(
	item: Rect2, chart: Rect2, y: float, g1: float, gutter: float, top: float
) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if item.get_center().x < chart.get_center().x:
		var margin: float = chart.position.x + 1 + (top - top_gutter_y)
		points = [Vector2(item.position.x - 1, y), Vector2(margin, y), Vector2(margin, top)]
	else:
		points = [Vector2(item.end.x, y), Vector2(g1, y)]
		if gutter == g1:
			return points
		points.append(Vector2(g1, top))
	points.append(Vector2(gutter, top))
	return points


## Where the thread meets each item, marked in the thread's colour: a fact's whole hit area, or a
## line's height along the panel frame on the gutter side, so the mark never covers text.
func caps(
	column_a: Column, item_a: Rect2, panel_a: Rect2, column_b: Column, item_b: Rect2, panel_b: Rect2
) -> Array[Rect2]:
	return [_cap(column_a, item_a, panel_a, column_b), _cap(column_b, item_b, panel_b, column_a)]


## The column an item group belongs to.
static func column_of(group: EvidenceItem.Group) -> Column:
	match group:
		EvidenceItem.Group.BODY:
			return Column.BODY
		EvidenceItem.Group.LAW:
			return Column.LAW
	return Column.TESTIMONY


func _cap(column: Column, item: Rect2, panel: Rect2, other: Column) -> Rect2:
	if column == Column.BODY:
		return item
	var exits_right: bool = column == Column.TESTIMONY and other == Column.LAW
	var x: float = panel.end.x - 1 if exits_right else panel.position.x
	return Rect2(x, item.position.y, 1, item.size.y)


func _mid_y(rect: Rect2) -> float:
	return floorf(rect.position.y + rect.size.y / 2.0)


func _reversed(points: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for index: int in range(points.size() - 1, -1, -1):
		out.append(points[index])
	return out
