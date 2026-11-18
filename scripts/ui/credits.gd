extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	accent_color = AMBER
	super._ready()

	var page := create_page("A GAME ABOUT THE CHOICES WE LEAVE BEHIND", "THE PLAYER BEFORE YOU", "Made with time, care, and a shared future.")
	page.add_child(make_label("Built with Godot 4  ·  GDScript  ·  JSON-based local data", 16, MUTED))

	var team := HBoxContainer.new()
	team.custom_minimum_size.y = 100
	team.add_theme_constant_override("separation", 12)
	page.add_child(team)
	for index in range(4):
		var name_slot := make_panel(AMBER)
		name_slot.custom_minimum_size = Vector2(180, 90)
		team.add_child(name_slot)
		name_slot.add_child(make_label("TEAM MEMBER %02d" % (index + 1), 12, MUTED))

	var back := make_back_button("res://scenes/ui/main_menu.tscn")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_child(back)
