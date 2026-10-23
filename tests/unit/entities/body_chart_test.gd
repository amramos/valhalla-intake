extends GutTest
## The slab (D35): a Night 4 rim and a Night 1 shadow, both outside the 128×100 chart and every
## hit area, never an Ashen value; the chart's own rect and hit areas are unchanged.

const Palette := preload("res://tests/unit/entities/desk_palette.gd")
const THEME := preload("res://scenes/desk/desk_theme.tres")


func test_the_slab_lies_outside_the_chart_and_every_hit_area() -> void:
	var chart: BodyChart = _chart()
	var items: Array[EvidenceItem] = []
	var index: int = 1
	for place: StringName in chart.place_rects:
		var view: StringName = &"back" if place == &"torso_back" else &"front"
		items.append(EvidenceItem.make("B%d" % index, EvidenceItem.Group.BODY, "fact", view, place))
		index += 1
	chart.show_facts(items)
	var inside := Rect2(Vector2.ZERO, BodyChart.CHART_SIZE)
	var crossings: Array[String] = []
	for rect: Rect2 in chart.slab_rects():
		if rect.intersects(inside):
			crossings.append("chart %s" % rect)
		for item: EvidenceItem in items:
			if rect.intersects(chart.area(item.id).get_rect()):
				crossings.append("%s %s" % [item.id, rect])
	assert_eq(crossings, [] as Array[String])
	assert_eq(chart.size, BodyChart.CHART_SIZE, "the node keeps its rect")
	assert_eq(Palette.bounds(chart.slab_rects()), Rect2(-2, -2, 134, 106), "2 px rim, 2 px shadow")


func test_the_rim_is_night_four_and_the_shadow_night_one() -> void:
	var named: Dictionary[String, Color] = Palette.by_name()
	assert_eq(
		THEME.get_color(&"slab_rim", &"DeskPalette").to_html(false), named["Night 4"].to_html(false)
	)
	assert_eq(
		THEME.get_color(&"slab_shadow", &"DeskPalette").to_html(false),
		named["Night 1"].to_html(false)
	)
	for ashen: String in ["Ashen 0", "Ashen 1", "Ashen 2"]:
		var rim: String = THEME.get_color(&"slab_rim", &"DeskPalette").to_html(false)
		assert_ne(rim, named[ashen].to_html(false), "D35: never Ashen")


func test_the_shadow_falls_below_and_right_only() -> void:
	var chart: BodyChart = _chart()
	var rects: Array[Rect2] = chart.slab_rects()
	var shadow: Rect2 = rects[0].merge(rects[1])
	assert_eq(shadow, Rect2(0, 0, 132, 104), "offset 2 px down and right from the rim")
	assert_true(rects[0].position.x >= BodyChart.CHART_SIZE.x, "right of the chart")
	assert_true(rects[1].position.y >= BodyChart.CHART_SIZE.y, "below the chart")


func _chart() -> BodyChart:
	var host := Control.new()
	host.theme = THEME
	add_child_autofree(host)
	var chart := BodyChart.new()
	chart.size = BodyChart.CHART_SIZE
	host.add_child(chart)
	return chart
