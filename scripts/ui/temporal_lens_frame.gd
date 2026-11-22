extends Control

var active := false
var elapsed := 0.0
var pulse := 0.0


func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	pulse += delta * 0.55
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	var center := size * 0.5
	var base_radius := minf(size.x, size.y) * 0.48
	var glow := 0.6 + sin(pulse) * 0.12
	for ring_index in range(3):
		var radius := base_radius - float(ring_index) * 10.0
		var alpha := (0.72 - float(ring_index) * 0.12) * glow
		draw_arc(center, radius, 0.0, TAU, 120, Color("#62e6f4", alpha), 2.4 - float(ring_index) * 0.5, true)
	var rotation := elapsed * 0.22
	for symbol_index in range(20):
		var angle := TAU * float(symbol_index) / 20.0 + rotation
		var inner := base_radius - 18.0
		var outer := inner - (9.0 if symbol_index % 5 == 0 else 4.0)
		draw_line(
			center + Vector2(cos(angle), sin(angle)) * inner,
			center + Vector2(cos(angle), sin(angle)) * outer,
			Color("#c7fbff", 0.75),
			1.4
		)
