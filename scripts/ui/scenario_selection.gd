extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	accent_color = CYAN
	super._ready()

	var page := create_page("CHOOSE YOUR STORY", "Select a Scenario", "One shared world. Two timelines. Every choice leaves a trace.")
	var cards := HBoxContainer.new()
	cards.custom_minimum_size.y = 270
	cards.add_theme_constant_override("separation", 16)
	page.add_child(cards)

	_add_scenario_card(
		cards,
		"01  /  DISASTER MANAGEMENT",
		"Flood Prevention",
		"A town faces a devastating flood. Prepare its future together.",
		"AVAILABLE",
		true
	)
	_add_scenario_card(
		cards,
		"02  /  MYSTERY",
		"Murder Mystery",
		"Uncover a truth hidden across time.",
		"COMING SOON",
		false
	)
	_add_scenario_card(
		cards,
		"03  /  INVESTIGATION",
		"Crime Investigation",
		"Follow the evidence. Change what comes next.",
		"COMING SOON",
		false
	)

	var back := make_back_button("res://scenes/ui/main_menu.tscn")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_child(back)


func _add_scenario_card(
	container: HBoxContainer,
	kicker: String,
	title: String,
	description: String,
	action_text: String,
	available: bool
) -> void:
	var panel := make_panel(CYAN if available else MUTED, available)
	container.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	content.add_child(make_label(kicker, 11, CYAN if available else MUTED))
	content.add_child(make_label(title, 21, PALE))
	var details := make_body_label(description, 14)
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(details)

	var action := make_button(action_text, available, CYAN)
	action.custom_minimum_size = Vector2(0, 46)
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.disabled = not available
	if available:
		action.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/disaster_introduction.tscn"))
	content.add_child(action)
