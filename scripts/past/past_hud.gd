extends CanvasLayer

signal set_decision_requested(action_id: String, selected: bool)
signal close_modal_requested
signal view_decisions_requested
signal submit_decisions_requested
signal submit_confirmed
signal submit_cancelled
signal resume_requested
signal main_menu_requested
signal cursor_toggle_requested

const PALE := Color("#eaf5ff")
const MUTED := Color("#9cb0c4")
const CYAN := Color("#4dd8e8")
const AMBER := Color("#ffb75e")
const DARK := Color("#081522")
const DECISIONS: Array[Dictionary] = [
	{"id": "repair_dam", "name": "Repair Dam", "cost": 30},
	{"id": "strengthen_bridge", "name": "Strengthen Bridge", "cost": 20},
	{"id": "improve_drainage", "name": "Improve Drainage", "cost": 15},
	{"id": "build_shelter", "name": "Emergency Shelter", "cost": 20},
	{"id": "install_warning_system", "name": "Warning System", "cost": 15},
]

var _root: Control
var _top_left_panel: PanelContainer
var _top_right_panel: PanelContainer
var _resources_column: VBoxContainer
var _completed_column: VBoxContainer
var _resource_heading: Label
var _improvements_heading: Label
var _budget_label: Label
var _improvements_label: Label
var _resource_progress: ProgressBar
var _prompt_panel: PanelContainer
var _interaction_prompt: Label
var _notice: Label
var _cursor_button: Button
var _view_button: Button
var _submit_button: Button
var _actions_bar: HBoxContainer
var _shade: ColorRect
var _modal_panel: PanelContainer
var _modal_content: VBoxContainer
var _modal_mode := ""
var _modal_tween: Tween
var _mouse_captured := true
var _last_decisions: Dictionary = {}
var _last_remaining := 70
var _notice_time := 0.0


func _ready() -> void:
	_build_interface()


func _process(delta: float) -> void:
	if _notice_time > 0.0:
		_notice_time -= delta
		if _notice_time <= 0.0:
			_notice.hide()


func refresh_status(remaining: int, decisions: Dictionary) -> void:
	_last_remaining = remaining
	_last_decisions = decisions.duplicate(true)
	var completed := 0
	for value in decisions.values():
		if bool(value):
			completed += 1
	_budget_label.text = "%02d / 70" % remaining
	_resource_progress.value = remaining
	_improvements_label.text = "%d / 5" % completed


func set_interaction_prompt(text: String) -> void:
	_interaction_prompt.text = text
	_interaction_prompt.visible = not text.is_empty()


func set_mouse_captured(captured: bool) -> void:
	_mouse_captured = captured
	_update_cursor_button_text()


func show_structure_panel(data: Dictionary, selected: bool) -> void:
	_modal_mode = "structure"
	_open_modal(Vector2(540, 430), "STRUCTURE INSPECTION")
	_modal_content.add_child(_make_label(str(data.get("name", "Structure")), 28, PALE))
	_modal_content.add_child(_make_label("CURRENT CONDITION   %s" % str(data.get("condition", "")), 13, AMBER))
	_modal_content.add_child(_make_wrapped_label(str(data.get("risk", "")), 15, MUTED))
	_modal_content.add_child(_make_label("AVAILABLE IMPROVEMENT", 12, CYAN))
	_modal_content.add_child(_make_wrapped_label(str(data.get("improvement", "")), 15, PALE))
	_modal_content.add_child(
		_make_label(
			"RESOURCE COST   %d POINTS" % int(data.get("cost", 0)),
			16,
			AMBER
		)
	)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	_modal_content.add_child(actions)
	var action_id := str(data.get("action_id", ""))
	var action_text := "UNDO IMPROVEMENT  (+%d)" % int(data.get("cost", 0)) if selected else "CONFIRM IMPROVEMENT"
	var improve := _make_button(action_text, true)
	improve.pressed.connect(func() -> void: set_decision_requested.emit(action_id, not selected))
	actions.add_child(improve)
	var cancel := _make_button("CANCEL")
	cancel.pressed.connect(func() -> void: close_modal_requested.emit())
	actions.add_child(cancel)


func show_decision_summary(decisions: Dictionary, remaining: int) -> void:
	refresh_status(remaining, decisions)
	_modal_mode = "summary"
	_open_modal(Vector2(590, 610), "PAST DECISION SUMMARY")
	_modal_content.add_child(_make_label("Selected improvements and their resource costs", 14, MUTED))

	for item in DECISIONS:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 42
		row.add_theme_constant_override("separation", 12)
		_modal_content.add_child(row)
		var action_id: String = item["id"]
		var selected := bool(decisions.get(action_id, false))
		var state_text := "SELECTED" if selected else "NOT SELECTED"
		var decision_label := _make_wrapped_label(
			"%s   ·   %d pts   ·   %s" % [item["name"], item["cost"], state_text],
			14,
			CYAN if selected else MUTED
		)
		decision_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		decision_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(decision_label)
		if selected:
			var undo := _make_button("UNDO", false)
			undo.custom_minimum_size = Vector2(90, 38)
			undo.pressed.connect(func() -> void: set_decision_requested.emit(action_id, false))
			row.add_child(undo)

	_modal_content.add_child(_make_label("REMAINING   %d / 70 RESOURCE POINTS" % remaining, 17, AMBER))
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	_modal_content.add_child(actions)
	var submit := _make_button("SUBMIT DECISIONS", true)
	submit.pressed.connect(func() -> void: submit_decisions_requested.emit())
	actions.add_child(submit)
	var close := _make_button("CLOSE")
	close.pressed.connect(func() -> void: close_modal_requested.emit())
	actions.add_child(close)


func show_submit_confirmation() -> void:
	_modal_mode = "submit_confirmation"
	_open_modal(Vector2(540, 300), "CONFIRM YOUR DECISIONS")
	_modal_content.add_child(
		_make_wrapped_label(
			"These choices will shape the town another player investigates in 2046. You may submit with resource points unused.",
			16,
			MUTED
		)
	)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	_modal_content.add_child(actions)
	var confirm := _make_button("SUBMIT TO THE FUTURE", true)
	confirm.pressed.connect(func() -> void: submit_confirmed.emit())
	actions.add_child(confirm)
	var cancel := _make_button("REVIEW DECISIONS")
	cancel.pressed.connect(func() -> void: submit_cancelled.emit())
	actions.add_child(cancel)


func show_pause_menu() -> void:
	_modal_mode = "pause"
	_open_modal(Vector2(480, 360), "PAUSED")
	_modal_content.add_child(_make_label("PAST TIMELINE  /  2026", 14, CYAN))
	var resume := _make_button("RESUME", true)
	resume.pressed.connect(func() -> void: resume_requested.emit())
	_modal_content.add_child(resume)
	var decisions := _make_button("VIEW DECISIONS")
	decisions.pressed.connect(func() -> void: view_decisions_requested.emit())
	_modal_content.add_child(decisions)
	var menu := _make_button("BACK TO MAIN MENU")
	menu.pressed.connect(func() -> void: main_menu_requested.emit())
	_modal_content.add_child(menu)


func close_modal() -> void:
	_modal_mode = ""
	_kill_modal_tween()
	_modal_tween = create_tween()
	_modal_tween.set_parallel(true)
	_modal_tween.tween_property(_modal_panel, "modulate:a", 0.0, 0.12)
	_modal_tween.tween_property(_shade, "color:a", 0.0, 0.12)
	_modal_tween.chain().tween_callback(func() -> void:
		_modal_panel.hide()
		_shade.hide()
		_modal_panel.modulate = Color.WHITE
		_shade.color.a = 0.78
	)


func show_notice(message: String) -> void:
	_notice.text = message
	_notice.show()
	_notice_time = 3.5


func get_modal_mode() -> String:
	return _modal_mode


func _build_interface() -> void:
	_root = Control.new()
	_root.name = "HUD"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.resized.connect(_layout_top_panels)
	_root.resized.connect(_layout_bottom_controls)
	add_child(_root)

	_build_top_bar()
	_build_bottom_controls()
	_layout_top_panels()

	_shade = ColorRect.new()
	_shade.color = Color(0.01, 0.035, 0.06, 0.78)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_shade.hide()
	_root.add_child(_shade)

	_modal_panel = PanelContainer.new()
	_modal_panel.set_anchors_preset(Control.PRESET_CENTER)
	_modal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_panel.add_theme_stylebox_override("panel", _panel_style(CYAN))
	_modal_panel.hide()
	_root.add_child(_modal_panel)

	_modal_content = VBoxContainer.new()
	_modal_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_modal_content.add_theme_constant_override("separation", 12)
	_modal_panel.add_child(_modal_content)

	_notice = _make_label("", 15, PALE)
	_notice.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_notice.offset_left = 200
	_notice.offset_top = 105
	_notice.offset_right = -200
	_notice.offset_bottom = 150
	_notice.add_theme_stylebox_override("normal", _panel_style(AMBER))
	_notice.hide()
	_root.add_child(_notice)


func _build_top_bar() -> void:
	_top_left_panel = PanelContainer.new()
	_top_left_panel.name = "TimelinePanel"
	_top_left_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_left_panel.add_theme_stylebox_override("panel", _panel_style(CYAN))
	_root.add_child(_top_left_panel)

	var mission := VBoxContainer.new()
	mission.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission.add_theme_constant_override("separation", 3)
	_top_left_panel.add_child(mission)
	mission.add_child(_make_single_line_label("PAST TIMELINE  —  2026", 16, CYAN, 250))
	mission.add_child(_make_single_line_label("Mission: Prepare the Town", 13, PALE, 250))

	_top_right_panel = PanelContainer.new()
	_top_right_panel.name = "ResourcePanel"
	_top_right_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_right_panel.add_theme_stylebox_override("panel", _panel_style(CYAN))
	_root.add_child(_top_right_panel)

	var stats := HBoxContainer.new()
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 12)
	_top_right_panel.add_child(stats)

	_resources_column = VBoxContainer.new()
	_resources_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resources_column.custom_minimum_size.x = 94
	_resources_column.add_theme_constant_override("separation", 1)
	stats.add_child(_resources_column)
	_resource_heading = _make_single_line_label("RESOURCE POINTS", 10, MUTED, 94)
	_resources_column.add_child(_resource_heading)
	_budget_label = _make_single_line_label("70 / 70", 17, PALE, 94)
	_resources_column.add_child(_budget_label)

	_resource_progress = ProgressBar.new()
	_resource_progress.name = "ResourceProgress"
	_resource_progress.custom_minimum_size = Vector2(120, 12)
	_resource_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_resource_progress.max_value = 70
	_resource_progress.value = 70
	_resource_progress.show_percentage = false
	_resource_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resource_progress.add_theme_stylebox_override("background", _progress_style(Color("#152b38")))
	_resource_progress.add_theme_stylebox_override("fill", _progress_style(CYAN))
	stats.add_child(_resource_progress)

	_completed_column = VBoxContainer.new()
	_completed_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_completed_column.custom_minimum_size.x = 116
	_completed_column.add_theme_constant_override("separation", 1)
	stats.add_child(_completed_column)
	_improvements_heading = _make_single_line_label("IMPROVEMENTS", 10, MUTED, 116)
	_completed_column.add_child(_improvements_heading)
	_improvements_label = _make_single_line_label("0 / 5", 17, PALE, 116)
	_completed_column.add_child(_improvements_label)


func _layout_top_panels() -> void:
	if _top_left_panel == null or _top_right_panel == null:
		return
	var viewport_width := _root.size.x
	var margin := clampf(viewport_width * 0.025, 14.0, 24.0)
	if viewport_width < 900.0:
		var card_width := maxf(viewport_width - margin * 2.0, 0.0)
		_set_panel_rect(_top_left_panel, margin, margin, card_width, 58.0)
		_set_panel_rect(_top_right_panel, margin, margin + 64.0, card_width, 58.0)
		if viewport_width < 460.0:
			_resources_column.custom_minimum_size.x = 76
			_resource_heading.text = "RESOURCES"
			_resource_heading.custom_minimum_size.x = 76
			_budget_label.custom_minimum_size.x = 76
			_resource_progress.custom_minimum_size.x = 64
			_completed_column.custom_minimum_size.x = 88
			_improvements_heading.text = "UPGRADES"
			_improvements_heading.custom_minimum_size.x = 88
			_improvements_label.custom_minimum_size.x = 88
		else:
			_resources_column.custom_minimum_size.x = 94
			_resource_heading.text = "RESOURCE POINTS"
			_resource_heading.custom_minimum_size.x = 94
			_budget_label.custom_minimum_size.x = 94
			_resource_progress.custom_minimum_size.x = 120
			_completed_column.custom_minimum_size.x = 116
			_improvements_heading.text = "IMPROVEMENTS"
			_improvements_heading.custom_minimum_size.x = 116
			_improvements_label.custom_minimum_size.x = 116
	else:
		_resources_column.custom_minimum_size.x = 94
		_resource_heading.text = "RESOURCE POINTS"
		_resource_heading.custom_minimum_size.x = 94
		_budget_label.custom_minimum_size.x = 94
		_resource_progress.custom_minimum_size.x = 120
		_completed_column.custom_minimum_size.x = 116
		_improvements_heading.text = "IMPROVEMENTS"
		_improvements_heading.custom_minimum_size.x = 116
		_improvements_label.custom_minimum_size.x = 116
		var left_width := clampf(viewport_width * 0.31, 250.0, 390.0)
		var right_width := clampf(viewport_width * 0.35, 385.0, 450.0)
		_set_panel_rect(_top_left_panel, margin, margin, left_width, 70.0)
		_set_panel_rect(_top_right_panel, viewport_width - margin - right_width, margin, right_width, 70.0)


func _set_panel_rect(panel: Control, left: float, top: float, width: float, height: float) -> void:
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = left
	panel.offset_top = top
	panel.offset_right = left + width
	panel.offset_bottom = top + height


func _build_bottom_controls() -> void:
	_prompt_panel = PanelContainer.new()
	_prompt_panel.name = "InteractionPromptPanel"
	_prompt_panel.anchor_top = 1.0
	_prompt_panel.anchor_bottom = 1.0
	_prompt_panel.offset_left = 22
	_prompt_panel.offset_top = -86
	_prompt_panel.offset_right = 400
	_prompt_panel.offset_bottom = -22
	_prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_panel.add_theme_stylebox_override("panel", _panel_style(CYAN))
	_root.add_child(_prompt_panel)
	_interaction_prompt = _make_single_line_label("Explore the town", 14, PALE, 300)
	_prompt_panel.add_child(_interaction_prompt)

	_actions_bar = HBoxContainer.new()
	_actions_bar.name = "GameplayActions"
	_actions_bar.anchor_left = 1.0
	_actions_bar.anchor_top = 1.0
	_actions_bar.anchor_right = 1.0
	_actions_bar.anchor_bottom = 1.0
	_actions_bar.offset_left = -700
	_actions_bar.offset_top = -86
	_actions_bar.offset_right = -22
	_actions_bar.offset_bottom = -22
	_actions_bar.alignment = BoxContainer.ALIGNMENT_END
	_actions_bar.add_theme_constant_override("separation", 8)
	_root.add_child(_actions_bar)

	_view_button = _make_button("VIEW DECISIONS")
	_view_button.pressed.connect(func() -> void: view_decisions_requested.emit())
	_actions_bar.add_child(_view_button)
	_submit_button = _make_button("SUBMIT DECISIONS", true)
	_submit_button.pressed.connect(func() -> void: submit_decisions_requested.emit())
	_actions_bar.add_child(_submit_button)
	_cursor_button = _make_button("RELEASE MOUSE  [TAB]")
	_cursor_button.custom_minimum_size.x = 205
	_cursor_button.tooltip_text = "Release or recapture the mouse. Tab also toggles it."
	_cursor_button.pressed.connect(func() -> void: cursor_toggle_requested.emit())
	_actions_bar.add_child(_cursor_button)
	_layout_bottom_controls()


func _layout_bottom_controls() -> void:
	if _prompt_panel == null or _actions_bar == null:
		return
	var viewport_width := _root.size.x
	if viewport_width < 1000.0:
		var margin := clampf(viewport_width * 0.025, 12.0, 20.0)
		_prompt_panel.anchor_left = 0.0
		_prompt_panel.anchor_right = 0.0
		_prompt_panel.offset_left = margin
		_prompt_panel.offset_right = viewport_width - margin
		_prompt_panel.offset_top = -138
		_prompt_panel.offset_bottom = -88
		_actions_bar.anchor_left = 0.0
		_actions_bar.anchor_right = 0.0
		_actions_bar.offset_left = margin
		_actions_bar.offset_right = viewport_width - margin
		_actions_bar.offset_top = -80
		_actions_bar.offset_bottom = -14
		_actions_bar.alignment = BoxContainer.ALIGNMENT_CENTER
		var button_width := maxf((viewport_width - margin * 2.0 - 20.0) / 3.0, 110.0)
		if viewport_width < 420.0:
			button_width = maxf((viewport_width - margin * 2.0 - 20.0) / 3.0, 80.0)
			_view_button.text = "DECISIONS"
			_submit_button.text = "SUBMIT"
		else:
			_view_button.text = "VIEW DECISIONS"
			_submit_button.text = "SUBMIT DECISIONS"
		_view_button.custom_minimum_size.x = button_width
		_submit_button.custom_minimum_size.x = button_width
		_cursor_button.custom_minimum_size.x = button_width
		_view_button.add_theme_font_size_override("font_size", 11)
		_submit_button.add_theme_font_size_override("font_size", 11)
		_cursor_button.add_theme_font_size_override("font_size", 11)
		_update_cursor_button_text()
	else:
		_prompt_panel.anchor_left = 0.0
		_prompt_panel.anchor_right = 0.0
		_prompt_panel.offset_left = 22
		_prompt_panel.offset_right = 400
		_prompt_panel.offset_top = -86
		_prompt_panel.offset_bottom = -22
		_actions_bar.anchor_left = 1.0
		_actions_bar.anchor_right = 1.0
		_actions_bar.offset_left = -700
		_actions_bar.offset_right = -22
		_actions_bar.offset_top = -86
		_actions_bar.offset_bottom = -22
		_actions_bar.alignment = BoxContainer.ALIGNMENT_END
		_view_button.custom_minimum_size.x = 155
		_submit_button.custom_minimum_size.x = 155
		_cursor_button.custom_minimum_size.x = 205
		_view_button.add_theme_font_size_override("font_size", 12)
		_submit_button.add_theme_font_size_override("font_size", 12)
		_cursor_button.add_theme_font_size_override("font_size", 12)
		_update_cursor_button_text()


func _update_cursor_button_text() -> void:
	if _cursor_button == null:
		return
	if _root.size.x < 420.0:
		_cursor_button.text = "MOUSE [TAB]"
	elif _root.size.x < 540.0:
		_cursor_button.text = "RELEASE [TAB]" if _mouse_captured else "CAPTURE [TAB]"
	else:
		_cursor_button.text = "RELEASE MOUSE  [TAB]" if _mouse_captured else "CAPTURE MOUSE  [TAB]"


func _open_modal(minimum_size: Vector2, heading: String) -> void:
	_kill_modal_tween()
	for child in _modal_content.get_children():
		_modal_content.remove_child(child)
		child.queue_free()
	_modal_panel.custom_minimum_size = minimum_size
	_modal_panel.offset_left = -minimum_size.x * 0.5
	_modal_panel.offset_top = -minimum_size.y * 0.5
	_modal_panel.offset_right = minimum_size.x * 0.5
	_modal_panel.offset_bottom = minimum_size.y * 0.5
	_modal_content.add_child(_make_label(heading, 14, CYAN))
	_shade.show()
	_modal_panel.show()
	_modal_panel.modulate = Color(1, 1, 1, 0)
	_modal_panel.scale = Vector2(0.97, 0.97)
	_shade.color.a = 0.0
	_modal_tween = create_tween()
	_modal_tween.set_parallel(true)
	_modal_tween.tween_property(_modal_panel, "modulate:a", 1.0, 0.16)
	_modal_tween.tween_property(_modal_panel, "scale", Vector2.ONE, 0.16)
	_modal_tween.tween_property(_shade, "color:a", 0.78, 0.16)


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_single_line_label(text: String, size: int, color: Color, minimum_width: float) -> Label:
	var label := _make_label(text, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.custom_minimum_size.x = minimum_width
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _make_wrapped_label(text: String, size: int, color: Color) -> Label:
	var label := _make_label(text, size, color)
	label.custom_minimum_size.x = 440
	return label


func _make_button(text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(155, 44)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", PALE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(primary, false))
	button.add_theme_stylebox_override("hover", _button_style(primary, true))
	button.add_theme_stylebox_override("pressed", _button_style(primary, true))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button


func _progress_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	return style


func _button_style(primary: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#123044") if primary else Color("#0a1a29")
	style.border_color = CYAN.lightened(0.1) if hovered else CYAN
	style.set_border_width_all(2 if primary else 1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _panel_style(border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(DARK, 0.84)
	style.border_color = Color(border_color, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _kill_modal_tween() -> void:
	if _modal_tween != null and _modal_tween.is_running():
		_modal_tween.kill()
