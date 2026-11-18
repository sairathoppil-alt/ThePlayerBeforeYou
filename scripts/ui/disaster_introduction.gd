extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	accent_color = CYAN
	super._ready()

	var page := create_page("MISSION BRIEFING  /  DISASTER MANAGEMENT", "Flood Prevention", "A devastating flood will strike this town in 2046.")
	var explanation := make_body_label(
		"In 2026, prepare the town with limited resources. In the future, another player will investigate what happened and send clues back through Time Echo.",
		16
	)
	explanation.custom_minimum_size = Vector2(820, 58)
	page.add_child(explanation)

	var timelines := HBoxContainer.new()
	timelines.custom_minimum_size.y = 132
	timelines.add_theme_constant_override("separation", 18)
	page.add_child(timelines)
	_add_timeline_card(timelines, "PAST TIMELINE", "2026", "Prepare the town", CYAN)
	_add_timeline_card(timelines, "FUTURE TIMELINE", "2046", "Investigate the aftermath", AMBER)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	page.add_child(actions)

	var back := make_back_button("res://scenes/ui/scenario_selection.tscn")
	actions.add_child(back)
	var begin := make_button("BEGIN MISSION", true, CYAN)
	begin.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/past/past_timeline.tscn"))
	actions.add_child(begin)


func _add_timeline_card(container: HBoxContainer, kicker: String, year: String, detail: String, timeline_accent: Color) -> void:
	var panel := make_panel(timeline_accent)
	container.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(content)
	content.add_child(make_label(kicker, 12, timeline_accent))
	content.add_child(make_label(year, 34, PALE))
	content.add_child(make_label(detail, 14, MUTED))
