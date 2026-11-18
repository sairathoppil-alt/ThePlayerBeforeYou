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
var _budget_label: Label
var _improvements_label: Label
var _interaction_prompt: Label
var _notice: Label
var _cursor_button: Button
var _shade: ColorRect
var _modal_panel: PanelContainer
var _modal_content: VBoxContainer
var _modal_mode := ""
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
	_budget_label.text = "RESOURCE POINTS   %02d / 70" % remaining
	_improvements_label.text = "IMPROVEMENTS   %d / 5" % completed


func set_interaction_prompt(text: String) -> void:
	_interaction_prompt.text = text
	_interaction_prompt.visible = not text.is_empty()


func set_mouse_captured(captured: bool) -> void:
	_cursor_button.text = "RELEASE MOUSE  [TAB]" if captured else "CAPTURE MOUSE  [TAB]"


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
	_modal_panel.hide()
	_shade.hide()


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
	add_child(_root)

	_build_top_bar()
	_build_bottom_controls()

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
	var panel := PanelContainer.new()
	panel.anchor_right = 1.0
	panel.offset_left = 22
	panel.offset_top = 18
	panel.offset_right = -22
	panel.offset_bottom = 86
	panel.add_theme_stylebox_override("panel", _panel_style(CYAN))
	_root.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	panel.add_child(row)
	var mission := _make_label("PAST TIMELINE  —  2026", 16, CYAN)
	mission.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(mission)
	var title := _make_label("MISSION   PREPARE THE TOWN", 14, PALE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	_budget_label = _make_label("RESOURCE POINTS   70 / 70", 14, AMBER)
	row.add_child(_budget_label)
	_improvements_label = _make_label("IMPROVEMENTS   0 / 5", 14, PALE)
	row.add_child(_improvements_label)


func _build_bottom_controls() -> void:
	var prompt_panel := PanelContainer.new()
	prompt_panel.anchor_top = 1.0
	prompt_panel.anchor_bottom = 1.0
	prompt_panel.offset_left = 22
	prompt_panel.offset_top = -86
	prompt_panel.offset_right = 400
	prompt_panel.offset_bottom = -22
	prompt_panel.add_theme_stylebox_override("panel", _panel_style(CYAN))
	_root.add_child(prompt_panel)
	_interaction_prompt = _make_label("Explore the town", 14, PALE)
	prompt_panel.add_child(_interaction_prompt)

	var actions := HBoxContainer.new()
	actions.anchor_left = 1.0
	actions.anchor_top = 1.0
	actions.anchor_right = 1.0
	actions.anchor_bottom = 1.0
	actions.offset_left = -700
	actions.offset_top = -86
	actions.offset_right = -22
	actions.offset_bottom = -22
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	_root.add_child(actions)

	var view := _make_button("VIEW DECISIONS")
	view.pressed.connect(func() -> void: view_decisions_requested.emit())
	actions.add_child(view)
	var submit := _make_button("SUBMIT DECISIONS", true)
	submit.pressed.connect(func() -> void: submit_decisions_requested.emit())
	actions.add_child(submit)
	_cursor_button = _make_button("RELEASE MOUSE  [TAB]")
	_cursor_button.custom_minimum_size.x = 205
	_cursor_button.pressed.connect(func() -> void: cursor_toggle_requested.emit())
	actions.add_child(_cursor_button)


func _open_modal(minimum_size: Vector2, heading: String) -> void:
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


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
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
	style.bg_color = Color(DARK, 0.96)
	style.border_color = Color(border_color, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style
