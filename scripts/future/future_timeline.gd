extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	accent_color = AMBER
	super._ready()

	var page := create_page("FUTURE TIMELINE  /  2046", "20 Years Later", "Your decisions have shaped this town.")
	var panel := make_panel(AMBER)
	panel.custom_minimum_size = Vector2(680, 150)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_child(panel)
	var message := make_label("Future investigation will be implemented in Stage 3.", 18, MUTED)
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(message)

	var back := make_button("BACK TO MAIN MENU", true, AMBER)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	page.add_child(back)
