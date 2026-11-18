extends Control

const NAVY := Color("#07111f")
const PANEL := Color("#0d1b2b")
const MUTED := Color("#91a4b8")
const PALE := Color("#eaf5ff")
const CYAN := Color("#4dd8e8")
const AMBER := Color("#ffb75e")

var accent_color: Color = CYAN
var _elapsed := 0.0


func _ready() -> void:
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	var size := get_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), NAVY)

	for x in range(0, int(size.x) + 1, 48):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.20, 0.38, 0.52, 0.07), 1.0)
	for y in range(0, int(size.y) + 1, 48):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.20, 0.38, 0.52, 0.07), 1.0)

	var center := Vector2(size.x * 0.5, size.y * 0.49)
	for radius in [170.0, 245.0, 320.0]:
		draw_arc(center, radius, 0.0, TAU, 96, Color(accent_color, 0.045), 1.0)

	var sweep_x := fposmod(_elapsed * 44.0, size.x + 140.0) - 70.0
	draw_line(Vector2(sweep_x, 0), Vector2(sweep_x, size.y), Color(accent_color, 0.055), 2.0)

	for index in range(12):
		var phase := float(index) * 0.73
		var point := Vector2(
			fposmod(phase * 211.0 + _elapsed * (7.0 + float(index % 4) * 2.0), size.x),
			fposmod(phase * 137.0 + float(index) * 59.0, size.y)
		)
		draw_circle(point, 1.4, Color(accent_color, 0.22))


func create_page(kicker: String, title: String, subtitle: String) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_right", 72)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)

	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.alignment = BoxContainer.ALIGNMENT_CENTER
	page.add_theme_constant_override("separation", 14)
	margin.add_child(page)

	var eyebrow := make_label(kicker.to_upper(), 13, accent_color)
	page.add_child(eyebrow)
	var heading := make_label(title, 42 if title.length() < 24 else 36, PALE)
	page.add_child(heading)
	var subheading := make_label(subtitle, 16, MUTED)
	subheading.custom_minimum_size.y = 28
	page.add_child(subheading)
	return page


func make_label(
	text: String,
	font_size: int,
	color: Color = PALE,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER
) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func make_body_label(text: String, font_size: int = 15) -> Label:
	var label := make_label(text, font_size, MUTED)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func make_button(text: String, primary: bool = false, button_accent: Color = CYAN) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260, 52)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", PALE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#607080"))
	button.add_theme_stylebox_override("normal", make_button_style(primary, button_accent, false))
	button.add_theme_stylebox_override("hover", make_button_style(primary, button_accent, true))
	button.add_theme_stylebox_override("pressed", make_button_style(primary, button_accent, true))
	button.add_theme_stylebox_override("disabled", make_button_style(false, Color("#425163"), false))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pivot_offset = button.custom_minimum_size * 0.5
	button.resized.connect(func() -> void: button.pivot_offset = button.size * 0.5)
	button.mouse_entered.connect(func() -> void: _animate_button(button, Vector2(1.025, 1.025)))
	button.mouse_exited.connect(func() -> void: _animate_button(button, Vector2.ONE))
	return button


func _animate_button(button: Button, target_scale: Vector2) -> void:
	button.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).tween_property(
		button, "scale", target_scale, 0.14
	)


func make_button_style(primary: bool, button_accent: Color, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = button_accent.darkened(0.48) if primary else Color("#0b1928")
	style.border_color = button_accent.lightened(0.12) if hovered else button_accent
	style.set_border_width_all(2 if primary else 1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	if hovered:
		style.shadow_color = Color(button_accent, 0.24)
		style.shadow_size = 8
	return style


func make_panel(panel_accent: Color = CYAN, active: bool = true) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0c1b2b") if active else Color("#0a1522")
	style.border_color = Color(panel_accent, 0.8) if active else Color("#243446")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	return panel


func make_back_button(target_scene: String) -> Button:
	var button := make_button("BACK")
	button.custom_minimum_size = Vector2(150, 48)
	button.pressed.connect(func() -> void: get_tree().change_scene_to_file(target_scene))
	return button
