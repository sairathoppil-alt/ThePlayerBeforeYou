extends Control

const CYAN := Color("#61d4df")
const AMBER := Color("#f2b96f")
const PALE := Color("#edf6f6")
const MUTED := Color("#aab7bc")
const TOWN_SCENE: PackedScene = preload("res://scenes/world/town_environment.tscn")

var _ending_camera: Camera3D
var _ending_time := 0.0


func _ready() -> void:
	_build_screen()


func _process(delta: float) -> void:
	_ending_time += delta
	if _ending_camera != null:
		_ending_camera.position.x = -38.0 + sin(_ending_time * 0.12) * 1.4
		_ending_camera.look_at(Vector3(-22.0, 2.5, 0.0), Vector3.UP)


func _build_screen() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var viewport_container := SubViewportContainer.new()
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport_container)
	var cinematic_viewport := SubViewport.new()
	cinematic_viewport.size = Vector2i(1280, 720)
	cinematic_viewport.own_world_3d = true
	cinematic_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	cinematic_viewport.handle_input_locally = false
	viewport_container.add_child(cinematic_viewport)
	var town := TOWN_SCENE.instantiate() as Node3D
	town.set("timeline_year", 2046)
	town.set("create_interactive_structures", false)
	town.set("visual_only", true)
	cinematic_viewport.add_child(town)
	_ending_camera = Camera3D.new()
	_ending_camera.position = Vector3(-38.0, 10.0, 13.0)
	_ending_camera.fov = 52.0
	cinematic_viewport.add_child(_ending_camera)
	_ending_camera.look_at(Vector3(-22.0, 2.5, 0.0), Vector3.UP)
	_ending_camera.current = true
	var background := ColorRect.new()
	background.color = Color(0.02, 0.055, 0.08, 0.63)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(740, 520)
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.modulate.a = 0.0
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)
	var title := Label.new()
	title.text = "THE FLOODGATE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", CYAN)
	content.add_child(title)
	var progress: Dictionary = AdventureState.get_state().get("mission_progress", {})
	var outcome := str(progress.get("final_outcome", "unresolved"))
	var subtitle := Label.new()
	subtitle.text = "A safer future, built across two timelines." if outcome == "prevented" else "The outcome remains uncertain."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", AMBER)
	content.add_child(subtitle)
	var summary := Label.new()
	summary.text = (
		"The 2026 floodgate was configured using evidence carried back from 2046. "
		+ "The changed spillway now protects Willowbrook while both players remain in their own timeline."
	)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 16)
	summary.add_theme_color_override("font_color", PALE)
	content.add_child(summary)
	var contributions: Array = progress.get("contributions", [])
	var past_count := 0
	var future_count := 0
	for contribution in contributions:
		if str(contribution.get("role", "")) == "past":
			past_count += 1
		elif str(contribution.get("role", "")) == "future":
			future_count += 1
	var roles := Label.new()
	roles.text = "PAST CONTRIBUTIONS  %d     ·     FUTURE CONTRIBUTIONS  %d" % [past_count, future_count]
	roles.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	roles.add_theme_font_size_override("font_size", 14)
	roles.add_theme_color_override("font_color", PALE)
	content.add_child(roles)
	var note := Label.new()
	note.text = "Progress is saved. You can continue exploring or return to the title screen."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color", MUTED)
	content.add_child(note)
	var continue_button := Button.new()
	continue_button.text = "CONTINUE EXPLORING"
	continue_button.custom_minimum_size = Vector2(260, 46)
	continue_button.add_theme_color_override("font_color", PALE)
	continue_button.add_theme_stylebox_override("normal", _button_style(CYAN))
	continue_button.add_theme_stylebox_override("hover", _button_style(CYAN.lightened(0.22)))
	continue_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/world/adventure_world.tscn")
	)
	content.add_child(continue_button)
	var menu_button := Button.new()
	menu_button.text = "MAIN MENU"
	menu_button.custom_minimum_size = Vector2(200, 42)
	menu_button.add_theme_color_override("font_color", PALE)
	menu_button.add_theme_stylebox_override("normal", _button_style(AMBER))
	menu_button.add_theme_stylebox_override("hover", _button_style(AMBER.lightened(0.22)))
	menu_button.pressed.connect(func() -> void:
		NetworkSession.leave_room()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	content.add_child(menu_button)
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.8)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#101e29")
	style.border_color = CYAN
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 48
	style.content_margin_right = 48
	style.content_margin_top = 36
	style.content_margin_bottom = 36
	return style


func _button_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#132632")
	style.border_color = accent
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
