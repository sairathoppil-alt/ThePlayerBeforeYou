extends Control

var strokes: Array = []
var _current_stroke: Array[Vector2] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(520, 300)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_current_stroke = [_normalized_point(event.position)]
		elif not _current_stroke.is_empty():
			if _current_stroke.size() > 1:
				strokes.append(_current_stroke.duplicate())
			_current_stroke.clear()
			queue_redraw()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if not _current_stroke.is_empty():
			var point := _normalized_point(event.position)
			if _current_stroke.back().distance_to(point) > 0.003:
				_current_stroke.append(point)
				queue_redraw()


func clear_strokes() -> void:
	strokes.clear()
	_current_stroke.clear()
	queue_redraw()


func undo_last_stroke() -> void:
	if not _current_stroke.is_empty():
		_current_stroke.clear()
	elif not strokes.is_empty():
		strokes.pop_back()
	queue_redraw()


func get_normalized_strokes() -> Array:
	var result: Array = []
	for stroke in strokes:
		var normalized: Array = []
		for point in stroke:
			normalized.append([point.x, point.y])
		result.append(normalized)
	return result


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#b9ad87"))
	for index in range(strokes.size()):
		_draw_stroke(strokes[index], Color("#253a35"))
	_draw_stroke(_current_stroke, Color("#253a35"))


func _draw_stroke(stroke: Array, color: Color) -> void:
	if stroke.size() < 2:
		return
	var points := PackedVector2Array()
	for point in stroke:
		points.append(Vector2(point.x * size.x, point.y * size.y))
	draw_polyline(points, color, 4.0, true)


func _normalized_point(position: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x / maxf(size.x, 1.0), 0.0, 1.0),
		clampf(position.y / maxf(size.y, 1.0), 0.0, 1.0)
	)
