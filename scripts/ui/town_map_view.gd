extends Control

var locations: Dictionary = {}
var markers: Array = []
var player_position := Vector3.ZERO
var partner_position := Vector3.ZERO
var partner_visible := false


func set_map_data(
	location_data: Dictionary,
	marker_data: Array,
	local_position: Vector3,
	remote_position: Vector3,
	show_partner: bool
) -> void:
	locations = location_data
	markers = marker_data
	player_position = local_position
	partner_position = remote_position
	partner_visible = show_partner
	queue_redraw()


func _draw() -> void:
	var bounds := Rect2(Vector2(12, 12), size - Vector2(24, 24))
	draw_rect(bounds, Color("#101d24"))
	draw_rect(bounds, Color("#3d6268"), false, 1.5)
	var river_y := bounds.position.y + bounds.size.y * 0.5
	draw_rect(Rect2(bounds.position.x, river_y - 15, bounds.size.x, 30), Color("#264b58"))
	for road_z in [-39.0, -22.0, 22.0, 39.0]:
		var point := _map_point(Vector3(0, 0, road_z), bounds)
		draw_line(
			Vector2(bounds.position.x + 2.0, point.y),
			Vector2(bounds.end.x - 2.0, point.y),
			Color("#839083", 0.42),
			4.0
		)
	for location_id in locations:
		var location: Vector3 = locations[location_id]
		var point := _map_point(location, bounds)
		var marked := false
		for marker in markers:
			if str(marker.get("location_id", "")) == str(location_id):
				marked = true
				break
		draw_circle(point, 4.0 if marked else 2.4, Color("#ffc474") if marked else Color("#b5c3b9"))
	var local_point := _map_point(player_position, bounds)
	draw_circle(local_point, 6.0, Color("#5ce3ed"))
	draw_arc(local_point, 9.0, 0.0, TAU, 28, Color("#bdfaff"), 1.2)
	if partner_visible:
		var remote_point := _map_point(partner_position, bounds)
		draw_circle(remote_point, 6.0, Color("#ffad6e"))
		draw_arc(remote_point, 9.0, 0.0, TAU, 28, Color("#ffe4c2"), 1.2)
	var font := get_theme_default_font()
	if font != null:
		draw_string(font, Vector2(bounds.position.x + 8, bounds.position.y + 17), "WILLOWBROOK", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#dce8df"))
		draw_string(font, Vector2(bounds.position.x + 8, bounds.end.y - 7), "RIVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#b4dce4"))


func _map_point(world_position: Vector3, bounds: Rect2) -> Vector2:
	return Vector2(
		lerpf(bounds.position.x + 8, bounds.end.x - 8, (world_position.x + 50.0) / 100.0),
		lerpf(bounds.position.y + 8, bounds.end.y - 8, (world_position.z + 50.0) / 100.0)
	)
